//
//  ProfileFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum ProfileFeature {

    struct State: BaseState {
        var profile: MyProfileResponseDTO? = nil
        var orders: [OrderDTO] = []
        var searchText: String = ""
        var isLoadingProfile: Bool = false
        var isLoadingOrders: Bool = false

        // Profile edit
        var isUploadingImage: Bool = false
        var isEditingNick: Bool = false
        var nickDraft: String = ""
        var nickError: String? = nil
        var isUpdatingNick: Bool = false

        // Review writing
        var reviewTarget: OrderDTO? = nil
        var reviewRating: Int = 5
        var reviewContent: String = ""
        var isSubmittingReview: Bool = false

        // Computed
        var filteredOrders: [OrderDTO] {
            guard !searchText.isEmpty else { return orders }
            let query = searchText.lowercased()
            return orders.filter { $0.activity.title.lowercased().contains(query) }
        }

        var totalSpent: Int {
            orders.reduce(0) { $0 + $1.totalPrice }
        }

        var totalPoints: Int {
            orders.reduce(0) { $0 + $1.activity.pointReward }
        }

        var categoryRankings: [(rank: Int, category: String)] {
            let counts = Dictionary(grouping: orders, by: { $0.activity.category })
                .mapValues(\.count)
                .sorted { $0.value > $1.value }
                .prefix(3)
            return counts.enumerated().map { (index, pair) in
                (rank: index + 1, category: pair.key)
            }
        }
    }

    enum Intent: BaseIntent {
        case onAppear
        case searchTextChanged(String)
        case writeReviewTapped(OrderDTO)
        case reviewRatingChanged(Int)
        case reviewContentChanged(String)
        case submitReview
        case reviewDismissed
        case profileImageSelected(Data)
        case nickEditTapped
        case nickChanged(String)
        case nickSaveTapped
        case nickEditDismissed
    }
}
