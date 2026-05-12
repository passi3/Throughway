//
//  HomeFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum HomeFeature {
    struct State: BaseState {
        var newActivities: [ActivitySummaryDTO] = []
        var geoPosts: [PostDTO] = []
        var isLoadingNewActivities: Bool = false
        var isLoadingMorePosts: Bool = false
        var nextCursor: String? = nil
        var likeOverrides: [String: Bool] = [:]
        var likeCountOverrides: [String: Int] = [:]
        var commentCountOverrides: [String: Int] = [:]
        var distanceKm: Double = 5.0
        var isDistanceEnabled: Bool = false
        var sortOrder: String = "createdAt"
        var myUserId: String = ""
    }

    enum Intent: BaseIntent {
        case start
        case fetchNewActivities(country: String?, category: String?)
        case distanceChanged(Double)
        case distanceToggled
        case likeTapped(PostDTO)
        case loadMorePosts
        case refreshPosts
        case sortChanged(String)
        case deletePost(String)
    }
}
