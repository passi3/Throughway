//
//  DetailViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class DetailViewModel: BaseViewModel<DetailFeature.State, DetailFeature.Intent> {
    let summary: ActivitySummaryDTO

    private let activityClient: ActivityAPIClient

    init(summary: ActivitySummaryDTO, activityClient: ActivityAPIClient = .live) {
        self.summary = summary
        self.activityClient = activityClient
        super.init(initialState: .init())
    }

    // 상세 조회 전까지 summary 데이터로 fallback
    var title: String { state.detail?.title ?? summary.title }
    var country: String { state.detail?.country ?? summary.country }
    var category: String { state.detail?.category ?? summary.category }
    var thumbnails: [String] { state.detail?.thumbnails ?? summary.thumbnails }
    var tags: [String] { state.detail?.tags ?? summary.tags }
    var price: ActivityPriceDTO { state.detail?.price ?? summary.price }
    var keepCount: Int { state.keepOverride?.keepCount ?? state.detail?.keepCount ?? summary.keepCount }
    var isKeep: Bool { state.keepOverride?.isKeep ?? state.detail?.isKeep ?? summary.isKeep }
    var pointReward: Int { state.detail?.pointReward ?? summary.pointReward }

    var rating: Double? { state.detail?.rating }
    var reviewCount: Int? { state.detail?.reviewCount }
    var restrictions: ActivityRestrictionsDTO? { state.detail?.restrictions }
    var geolocation: GeolocationDTO { state.detail?.geolocation ?? summary.geolocation }
    var schedule: [ActivityScheduleItemDTO] { state.detail?.schedule ?? [] }

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
        }
    }

    private func toggleKeep() async {
        let newIsKeep = !isKeep
        let newCount = max(0, keepCount + (newIsKeep ? 1 : -1))
        reduce { $0.keepOverride = (newIsKeep, newCount) }
        do {
            let response = try await activityClient.toggleKeep(summary.activityId, newIsKeep)
            let confirmedIsKeep = response.keepStatus
            let confirmedCount = max(0, keepCount + (confirmedIsKeep == newIsKeep ? 0 : (confirmedIsKeep ? 1 : -1)))
            reduce { $0.keepOverride = (confirmedIsKeep, newCount) }
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
}
