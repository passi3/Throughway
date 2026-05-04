//
//  UserProfileFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum UserProfileFeature {
    enum Tab: CaseIterable {
        case posts, reviews
    }

    struct State: BaseState {
        var isCreatingRoom: Bool = false
        var selectedTab: Tab = .posts
        var posts: [PostDTO] = []
        var reviews: [ActivitySummaryDTO] = []
        var isLoadingPosts: Bool = false
        var isLoadingReviews: Bool = false
    }

    enum Intent: BaseIntent {
        case onAppear
        case tabChanged(Tab)
        case chatTapped
    }
}
