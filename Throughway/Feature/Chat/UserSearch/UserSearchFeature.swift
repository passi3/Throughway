//
//  UserSearchFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum UserSearchFeature {
    struct State: BaseState {
        var query: String = ""
        var results: [UserInfoResponseDTO] = []
        var isLoading: Bool = false
        var hasSearched: Bool = false
    }

    enum Intent: BaseIntent {
        case queryChanged(String)
        case searchSubmitted
    }
}
