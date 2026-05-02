//
//  ProfileFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum ProfileFeature {
    struct State: BaseState {
        var myKeeps: [ActivitySummaryDTO] = []
        var isLoading: Bool = false
    }

    enum Intent: BaseIntent {
        case onAppear
    }
}
