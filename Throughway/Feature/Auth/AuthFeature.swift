//
//  AuthFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum AuthFeature {
    struct State: BaseState {
        var phase: Phase = .loading
        var navigationPath: [AuthRoute] = []
    }

    enum Phase {
        case loading
        case unauthenticated
        case authenticated
    }

    enum Intent: BaseIntent {
        case start
        case handleForeground
        case logoutTapped
        case navigateToSignUp
        case navigationPathChanged([AuthRoute])
        case sessionStored(AuthTokens)
        case sessionInvalidated
        case phaseChanged(Phase)
        case resetToUnauthenticated
    }
}
