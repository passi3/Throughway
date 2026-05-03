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
        var likeCountOverrides: [String: Int] = [:]
        var distanceKm: Double = 5.0
    }

    enum Intent: BaseIntent {
        case start
        case fetchNewActivities(country: String?, category: String?)
        case distanceChanged(Double)
        case likeTapped(PostDTO)
    }
}
