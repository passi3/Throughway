//
//  MoreActivitiesFeature.swift
//  Throughway
//
//  Created by passi on 5/6/26.
//

import Foundation

enum MoreActivitiesFeature {
    struct State: BaseState {
        var recommended: [ActivitySummaryDTO] = []
        var exciting: [ActivitySummaryDTO] = []
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
