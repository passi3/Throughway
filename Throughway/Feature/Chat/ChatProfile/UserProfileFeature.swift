//
//  UserProfileFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum UserProfileFeature {
    struct State: BaseState {
        var isCreatingRoom: Bool = false
    }

    enum Intent: BaseIntent {
        case chatTapped
    }
}
