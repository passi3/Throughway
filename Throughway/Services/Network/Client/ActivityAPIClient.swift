//
//  ActivityAPIClient.swift
//  Throughway
//
//  Created by passi on 4/29/26.
//

import Foundation

struct ActivityAPIClient {
    var fetchList:        @Sendable (String?, String?, String?, Int?) async throws -> ActivityListResponseDTO
    var fetchNew:         @Sendable (String?, String?) async throws -> ActivityListResponseDTO
    var fetchDetail:      @Sendable (String) async throws -> ActivityDetailDTO
    var search:           @Sendable (String) async throws -> ActivitySearchResponseDTO
    var toggleKeep:       @Sendable (String, Bool) async throws -> KeepToggleResponseDTO
    var fetchMyKeeps:     @Sendable () async throws -> ActivityListResponseDTO
    var fetchUserReviews: @Sendable (String) async throws -> ActivityListResponseDTO
}

extension ActivityAPIClient {
    static let live: ActivityAPIClient = {
        let network = SharedNetwork.manager
        return Self(
            fetchList: { country, category, next, limit in
                try await network.request(ActivityRouter.fetchList(country: country, category: category, next: next, limit: limit))
            },
            fetchNew: { country, category in
                try await network.request(ActivityRouter.fetchNew(country: country, category: category))
            },
            fetchDetail: { id in
                try await network.request(ActivityRouter.fetchDetail(activityId: id))
            },
            search: { query in
                try await network.request(ActivityRouter.search(query: query))
            },
            toggleKeep: { id, keepStatus in
                try await network.request(ActivityRouter.toggleKeep(activityId: id, keepStatus: keepStatus))
            },
            fetchMyKeeps: {
                try await network.request(ActivityRouter.fetchMyKeeps)
            },
            fetchUserReviews: { userId in
                try await network.request(ActivityRouter.fetchUserReviews(userId: userId))
            }
        )
    }()
}

