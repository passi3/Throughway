//
//  PostAPIClient.swift
//  Throughway
//
//  Created by passi on 4/29/26.
//

import Foundation

struct PostAPIClient {
    var uploadFiles:        @Sendable ([Data]) async throws -> PostFilesResponseDTO
    var createPost:         @Sendable (CreatePostRequestDTO) async throws -> PostDTO
    var fetchByGeolocation: @Sendable (Double, Double, Int, String?, Int?) async throws -> PostListResponseDTO
    var searchByTitle:      @Sendable (String) async throws -> PostListResponseDTO
    var fetchDetail:        @Sendable (String) async throws -> PostDTO
    var updatePost:         @Sendable (String, UpdatePostRequestDTO) async throws -> PostDTO
    var deletePost:         @Sendable (String) async throws -> Void
    var toggleLike:         @Sendable (String, Bool) async throws -> LikeToggleResponseDTO
    var fetchUserPosts:     @Sendable (String) async throws -> PostListResponseDTO
    var fetchMyLikedPosts:  @Sendable () async throws -> PostListResponseDTO
    var createComment:      @Sendable (String, CreateCommentRequestDTO) async throws -> CommentDTO
    var deleteComment:      @Sendable (String, String) async throws -> Void
    var updateComment:      @Sendable (String, String, UpdateCommentRequestDTO) async throws -> CommentDTO
}

extension PostAPIClient {
    static let live: PostAPIClient = {
        let network = SharedNetwork.manager
        return Self(
            uploadFiles: { files in
                try await network.request(PostRouter.uploadFiles(files))
            },
            createPost: { dto in
                try await network.request(PostRouter.createPost(dto))
            },
            fetchByGeolocation: { lat, lon, distance, next, limit in
                try await network.request(PostRouter.fetchByGeolocation(latitude: lat, longitude: lon, distance: distance, next: next, limit: limit))
            },
            searchByTitle: { query in
                try await network.request(PostRouter.searchByTitle(query: query))
            },
            fetchDetail: { id in
                try await network.request(PostRouter.fetchDetail(postId: id))
            },
            updatePost: { id, dto in
                try await network.request(PostRouter.updatePost(postId: id, dto))
            },
            deletePost: { id in
                try await network.request(PostRouter.deletePost(postId: id))
            },
            toggleLike: { id, status in
                try await network.request(PostRouter.toggleLike(postId: id, body: LikeToggleRequestDTO(likeStatus: status)))
            },
            fetchUserPosts: { userId in
                try await network.request(PostRouter.fetchUserPosts(userId: userId))
            },
            fetchMyLikedPosts: {
                try await network.request(PostRouter.fetchMyLikedPosts)
            },
            createComment: { postId, dto in
                try await network.request(PostRouter.createComment(postId: postId, body: dto))
            },
            deleteComment: { postId, commentId in
                try await network.request(PostRouter.deleteComment(postId: postId, commentId: commentId))
            },
            updateComment: { postId, commentId, dto in
                try await network.request(PostRouter.updateComment(postId: postId, commentId: commentId, body: dto))
            }
        )
    }()
}
