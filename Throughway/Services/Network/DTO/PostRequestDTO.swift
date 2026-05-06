//
//  PostRequestDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

struct CreatePostRequestDTO: Encodable, Sendable {
    let title: String
    let content: String
    let files: [String]
    let activityId: String?

    enum CodingKeys: String, CodingKey {
        case title
        case content
        case files
        case activityId = "activity_id"
    }
}

struct UpdatePostRequestDTO: Encodable, Sendable {
    let title: String?
    let content: String?
    let files: [String]?
}

struct CreateCommentRequestDTO: Encodable, Sendable {
    let content: String
    let parentCommentId: String?

    enum CodingKeys: String, CodingKey {
        case content
        case parentCommentId = "parent_comment_id"
    }
}

struct UpdateCommentRequestDTO: Encodable, Sendable {
    let content: String
}

struct LikeToggleRequestDTO: Encodable, Sendable {
    let likeStatus: Bool

    enum CodingKeys: String, CodingKey {
        case likeStatus = "like_status"
    }
}
