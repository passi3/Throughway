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
        var posts: [PostDTO] = []
        var isLoadingPosts: Bool = false
    }

    enum Intent: BaseIntent {
        case onAppear
        case chatTapped
    }
}
