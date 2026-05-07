//
//  DetailViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation
import iamport_ios
import Then

@MainActor
final class DetailViewModel: BaseViewModel<DetailFeature.State, DetailFeature.Intent> {
    let summary: ActivitySummaryDTO

    private let activityClient: ActivityAPIClient
    private let orderPaymentClient: OrderPaymentAPIClient

    /// IamportPayment는 참조 타입이라 State 외부에서 보관.
    /// isPaymentPresented가 true로 바뀌기 직전에 설정된다.
    private(set) var pendingPayment: IamportPayment?

    init(
        summary: ActivitySummaryDTO,
        activityClient: ActivityAPIClient = .live,
        orderPaymentClient: OrderPaymentAPIClient = .live
    ) {
        self.summary = summary
        self.activityClient = activityClient
        self.orderPaymentClient = orderPaymentClient
        super.init(initialState: .init())
    }

    // MARK: - Computed (detail 로드 전 summary로 fallback)

    var title: String          { state.detail?.title       ?? summary.title }
    var country: String        { state.detail?.country     ?? summary.country }
    var category: String       { state.detail?.category    ?? summary.category }
    var thumbnails: [String]   { state.detail?.thumbnails  ?? summary.thumbnails }
    var tags: [String]         { state.detail?.tags        ?? summary.tags }
    var price: ActivityPriceDTO { state.detail?.price      ?? summary.price }
    var keepCount: Int { state.keepOverride?.keepCount ?? state.detail?.keepCount ?? summary.keepCount }
    var isKeep: Bool   { state.keepOverride?.isKeep   ?? state.detail?.isKeep   ?? summary.isKeep }
    var pointReward: Int { state.detail?.pointReward ?? summary.pointReward }

    var rating: Double?                   { state.detail?.rating }
    var reviewCount: Int?                 { state.detail?.reviewCount }
    var restrictions: ActivityRestrictionsDTO? { state.detail?.restrictions }
    var geolocation: GeolocationDTO { state.detail?.geolocation ?? summary.geolocation }
    var schedule: [ActivityScheduleItemDTO]    { state.detail?.schedule ?? [] }

    var discountPercent: Int? {
        let orig = price.original, fin = price.final
        guard orig > 0, fin < orig else { return nil }
        return Int(round(Double(orig - fin) / Double(orig) * 100))
    }

    var availableDates: [String] {
        state.detail?.reservationList.map { $0.itemName } ?? []
    }

    var availableTimes: [String] {
        guard let detail = state.detail,
              state.selectedDateIndex < detail.reservationList.count else { return [] }
        return detail.reservationList[state.selectedDateIndex]
            .times
            .filter { !$0.isReserved }
            .map { $0.time }
    }

    /// 날짜·시간이 모두 선택된 경우에만 결제 버튼 활성화
    var isPaymentReady: Bool {
        !availableDates.isEmpty && state.selectedTime != nil
    }

    // MARK: - Intent Handling

    override func send(_ intent: DetailFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchDetail() }

        case .dateSelected(let index):
            reduce {
                $0.selectedDateIndex = index
                $0.selectedTime = nil
            }

        case .timeSelected(let time):
            reduce { $0.selectedTime = time }

        case .keepToggled:
            Task { await toggleKeep() }

        case .participantCountChanged(let count):
            let maxCount = restrictions?.maxParticipants ?? 99
            reduce { $0.participantCount = min(maxCount, max(1, count)) }

        case .paymentTapped:
            Task { await createOrderAndPay() }
            // paymentPhase는 sheet 표시 후 Portone 응답까지 idle 유지

        case .paymentResponseReceived(let impUid, let success):
            print("[Iamport] success : \(success)")
            print("[Iamport] imp_uid : \(impUid ?? "nil")")
            guard success, let impUid else {
                reduce {
                    $0.isPaymentPresented = false
                    $0.paymentPhase = .failure("결제가 취소되었습니다.")
                }
                pendingPayment = nil
                return
            }
            Task { await validatePayment(impUid: impUid) }

        case .paymentDismissed:
            // Sheet가 사용자에 의해 닫힌 경우.
            // validating / success 중이면 이미 처리된 것이므로 무시.
            switch state.paymentPhase {
            case .validating, .success:
                return
            default:
                reduce {
                    $0.isPaymentPresented = false
                    if !$0.paymentPhase.isTerminal {
                        $0.paymentPhase = .failure("결제가 취소되었습니다.")
                    }
                }
                pendingPayment = nil
            }

        case .paymentAlertDismissed:
            reduce { $0.paymentPhase = .idle }
        }
    }

    // MARK: - Private

    private func fetchDetail() async {
        reduce { $0.isLoading = true }
        do {
            let detail = try await activityClient.fetchDetail(summary.activityId)
            reduce { $0.detail = detail }
        } catch {
            print("[Detail] fetchDetail failed: \(error.localizedDescription)")
        }
        reduce { $0.isLoading = false }
    }

    private func toggleKeep() async {
        let newIsKeep = !isKeep
        let newCount = max(0, keepCount + (newIsKeep ? 1 : -1))
        reduce { $0.keepOverride = (isKeep: newIsKeep, keepCount: newCount) }
        do {
            let response = try await activityClient.toggleKeep(summary.activityId, newIsKeep)
            let confirmedIsKeep = response.keepStatus
            reduce { $0.keepOverride = (isKeep: confirmedIsKeep, keepCount: newCount) }
            NotificationCenter.default.post(
                name: .activityKeepDidChange,
                object: nil,
                userInfo: ["activityId": summary.activityId, "isKeep": confirmedIsKeep, "keepCount": newCount]
            )
        } catch {
            reduce { $0.keepOverride = nil }
            print("[Detail] toggleKeep failed: \(error.localizedDescription)")
        }
    }

    // MARK: Step 1 — 주문 생성 → IamportPayment 구성 → 결제 시트 표시

    private func createOrderAndPay() async {
        guard let selectedTime = state.selectedTime,
              state.selectedDateIndex < availableDates.count else { return }

        let scheduleDate = availableDates[state.selectedDateIndex]
        let totalPrice   = price.final * state.participantCount

        reduce { $0.paymentPhase = .validating }   // 주문 생성 중 버튼 비활성

        let requestDTO = CreateOrderRequestDTO(
            activityId: summary.activityId,
            reservationItemName: scheduleDate,
            reservationItemTime: selectedTime,
            participantCount: state.participantCount,
            totalPrice: totalPrice
        )
        print("[Order] ▶ POST /v1/orders")
        print("  activity_id          : \(requestDTO.activityId)")
        print("  reservation_item_name: \(requestDTO.reservationItemName)")
        print("  reservation_item_time: \(requestDTO.reservationItemTime)")
        print("  participant_count    : \(requestDTO.participantCount)")
        print("  total_price          : \(requestDTO.totalPrice)")

        do {
            let order = try await orderPaymentClient.createOrder(requestDTO)
            print("[Order] ✅ order_code: \(order.orderCode), total_price: \(order.totalPrice)")

            let payment = IamportPayment(
                pg: PG.html5_inicis.makePgRawName(pgId: "INIpayTest"),
                merchant_uid: order.orderCode,   // 서버 order_code = merchant_uid
                amount: "\(order.totalPrice)"    // 검증 금액과 반드시 일치
            ).then {
                $0.pay_method = PayMethod.card.rawValue
                $0.name       = self.title
                $0.buyer_name = AppSession.userNick.isEmpty ? "구매자" : AppSession.userNick
                $0.app_scheme = "throughway"
            }

            pendingPayment = payment
            reduce {
                $0.paymentPhase = .idle
                $0.isPaymentPresented = true
            }
        } catch {
            print("[Order] ❌ 주문 생성 실패: \(error)")
            reduce { $0.paymentPhase = .failure("주문 생성에 실패했습니다.\n\(error.localizedDescription)") }
        }
    }

    // MARK: Step 2 — 결제 영수증 검증 (/v1/payments/validation)

    private func validatePayment(impUid: String) async {
        reduce {
            $0.isPaymentPresented = false
            $0.paymentPhase = .validating
        }
        pendingPayment = nil

        print("[Validate] ▶ POST /v1/payments/validation")
        print("[Validate] imp_uid: \(impUid)")

        do {
            let receipt = try await orderPaymentClient.validateReceipt(
                PaymentValidationRequestDTO(impUid: impUid)
            )
            print("[Validate] ✅ 성공 payment_id: \(receipt.paymentId)")
            reduce { $0.paymentPhase = .success }
        } catch {
            print("[Validate] ❌ 실패: \(error)")
            reduce {
                $0.paymentPhase = .failure("결제 검증에 실패했습니다.\n\(error.localizedDescription)")
            }
        }
    }
}
