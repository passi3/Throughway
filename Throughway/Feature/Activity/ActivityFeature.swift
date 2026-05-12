//
//  ActivityFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum ActivityFeature {
    struct State: BaseState {
        var activities: [ActivitySummaryDTO] = []
        var banners: [BannerItemDTO] = []
        var isLoading: Bool = false
        var webViewURL: URL?
        var keepOverrides: [String: (isKeep: Bool, keepCount: Int)] = [:]
    }

    enum Intent: BaseIntent {
        case onAppear
        case bannerTapped(BannerItemDTO)
        case webViewDismissed
        case keepToggled(activityId: String)
    }
}

enum ActivitySearchFeature {
    struct State: BaseState {
        var results: [ActivitySummaryDTO] = []
        var banners: [BannerItemDTO] = []
        var isLoading: Bool = false
        var hasSearched: Bool = false
        var webViewURL: URL?
        var keepOverrides: [String: (isKeep: Bool, keepCount: Int)] = [:]
    }

    enum Intent: BaseIntent {
        case onAppear
        case searchSubmitted(String)
        case reset
        case keepToggled(activityId: String)
        case keepUpdated(activityId: String, isKeep: Bool, keepCount: Int)
        case bannerTapped(BannerItemDTO)
        case webViewDismissed
    }
}
