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
    }

    enum Intent: BaseIntent {
        case onAppear
        case bannerTapped(BannerItemDTO)
        case webViewDismissed
    }
}

enum ActivitySearchFeature {
    struct State: BaseState {
        var results: [ActivitySummaryDTO] = []
        var isLoading: Bool = false
        var hasSearched: Bool = false
    }

    enum Intent: BaseIntent {
        case searchSubmitted(String)
        case reset
    }
}
