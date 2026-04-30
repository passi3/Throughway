//
//  ReviewAPIClient.swift
//  Throughway
//
//  Created by passi on 4/29/26.
//

import Foundation

struct ReviewAPIClient {
    var uploadFiles:   @Sendable (String, [Data]) async throws -> ReviewFilesResponseDTO
    var createReview:  @Sendable (String, CreateReviewRequestDTO) async throws -> ReviewDTO
    var fetchList:     @Sendable (String) async throws -> ReviewListResponseDTO
    var fetchDetail:   @Sendable (String, String) async throws -> ReviewDTO
    var updateReview:  @Sendable (String, String, UpdateReviewRequestDTO) async throws -> ReviewDTO
    var deleteReview:  @Sendable (String, String) async throws -> Void
    var fetchRatings:  @Sendable (String) async throws -> ReviewRatingsDTO
}

extension ReviewAPIClient {
    static let live: ReviewAPIClient = {
        let network = SharedNetwork.manager
        return Self(
            uploadFiles: { activityId, files in
                try await network.request(ReviewRouter.uploadFiles(activityId: activityId, files))
            },
            createReview: { activityId, dto in
                try await network.request(ReviewRouter.createReview(activityId: activityId, dto))
            },
            fetchList: { activityId in
                try await network.request(ReviewRouter.fetchList(activityId: activityId))
            },
            fetchDetail: { activityId, reviewId in
                try await network.request(ReviewRouter.fetchDetail(activityId: activityId, reviewId: reviewId))
            },
            updateReview: { activityId, reviewId, dto in
                try await network.request(ReviewRouter.updateReview(activityId: activityId, reviewId: reviewId, dto))
            },
            deleteReview: { activityId, reviewId in
                try await network.request(ReviewRouter.deleteReview(activityId: activityId, reviewId: reviewId))
            },
            fetchRatings: { activityId in
                try await network.request(ReviewRouter.fetchRatings(activityId: activityId))
            }
        )
    }()
}
