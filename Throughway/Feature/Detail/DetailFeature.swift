//
//  DetailFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum DetailFeature {
    struct State: BaseState {
        var detail: ActivityDetailDTO?
        var isLoading: Bool = false
        var selectedDateIndex: Int = 0
        var selectedTime: String?
        var keepOverride: (isKeep: Bool, keepCount: Int)? = nil

        // MARK: - Payment
        var participantCount: Int = 1
        var isPaymentPresented: Bool = false
        var paymentPhase: PaymentPhase = .idle
    }

    // MARK: - PaymentPhase

    /// 결제 단계 상태 머신
    enum PaymentPhase: Equatable {
        case idle
        case validating     // 결제 영수증 검증 중
        case success        // 검증 완료 → 결제 성공
        case failure(String)

        var isInProgress: Bool {
            self == .validating
        }

        var isTerminal: Bool {
            switch self {
            case .success, .failure: return true
            default: return false
            }
        }
    }

    // MARK: - Intent

    enum Intent: BaseIntent {
        case onAppear
        case dateSelected(Int)
        case timeSelected(String)
        case keepToggled

        // Payment intents
        case participantCountChanged(Int)
        case paymentTapped
        case paymentResponseReceived(impUid: String?, success: Bool)
        case paymentDismissed       // Sheet가 사용자 동작으로 닫힘
        case paymentAlertDismissed  // 성공/실패 알림을 사용자가 닫음
    }
}
