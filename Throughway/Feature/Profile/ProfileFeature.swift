//
//  ProfileFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum ProfileFeature {
    enum Tab: CaseIterable {
        case posts, reviews
    }

    struct State: BaseState {
        var profile: MyProfileResponseDTO? = nil
        var posts: [PostDTO] = []
        var reviews: [ActivitySummaryDTO] = []
        var selectedTab: Tab = .posts
        var isLoadingProfile: Bool = false
        var isLoadingPosts: Bool = false
        var isLoadingReviews: Bool = false
        var isUploadingImage: Bool = false
        var isEditingNick: Bool = false
        var nickDraft: String = ""
        var nickError: String? = nil
        var isUpdatingNick: Bool = false
    }

    enum Intent: BaseIntent {
        case onAppear
        case tabChanged(Tab)
        case profileImageSelected(Data)
        case nickEditTapped
        case nickChanged(String)
        case nickSaveTapped
        case nickEditDismissed
    }
}
