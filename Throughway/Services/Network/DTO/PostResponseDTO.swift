//
//  PostResponseDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

struct PostActivityDTO: Decodable, Sendable {
    let activityId: String

    enum CodingKeys: String, CodingKey {
        case activityId = "id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityId = container.decodeLossyString(forKey: .activityId)
    }
}

struct PostDTO: Decodable, Sendable {
    let postId: String
    let country: String?
    let category: String?
    let title: String
    let content: String
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let commentCount: Int
    let creator: PostCreatorDTO
    let activity: PostActivityDTO?
    let geolocation: GeolocationDTO?
    let comments: [CommentDTO]
    let createdAt: String
    let updatedAt: String?

    var activityId: String? { activity?.activityId }
    var displayCommentCount: Int { comments.reduce(0) { $0 + 1 + $1.replies.count } }

    enum CodingKeys: String, CodingKey {
        case postId       = "post_id"
        case country
        case category
        case title
        case content
        case files
        case isLike       = "is_like"
        case likeCount    = "like_count"
        case commentCount = "comment_count"
        case creator
        case activity
        case geolocation
        case comments
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postId        = container.decodeLossyString(forKey: .postId)
        country       = try container.decodeIfPresent(String.self, forKey: .country)
        category      = try container.decodeIfPresent(String.self, forKey: .category)
        title         = try container.decode(String.self, forKey: .title)
        content       = try container.decode(String.self, forKey: .content)
        files         = try container.decodeIfPresent([String].self, forKey: .files) ?? []
        isLike        = try container.decodeIfPresent(Bool.self, forKey: .isLike) ?? false
        likeCount     = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        commentCount  = try container.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        creator       = try container.decode(PostCreatorDTO.self, forKey: .creator)
        activity      = try container.decodeIfPresent(PostActivityDTO.self, forKey: .activity)
        geolocation   = try container.decodeIfPresent(GeolocationDTO.self, forKey: .geolocation)
        comments      = try container.decodeIfPresent([CommentDTO].self, forKey: .comments) ?? []
        createdAt     = try container.decode(String.self, forKey: .createdAt)
        updatedAt     = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }
}

struct PostCreatorDTO: Decodable, Sendable {
    let userId: String
    let nick: String
    let profileImage: String?
    let introduction: String?

    enum CodingKeys: String, CodingKey {
        case userId       = "user_id"
        case nick
        case profileImage
        case introduction
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userId = container.decodeLossyString(forKey: .userId)
        nick = try container.decode(String.self, forKey: .nick)
        profileImage = try container.decodeIfPresent(String.self, forKey: .profileImage)
        introduction = try container.decodeIfPresent(String.self, forKey: .introduction)
    }
}

extension PostCreatorDTO {
    var asUserInfo: UserInfoResponseDTO {
        UserInfoResponseDTO(userId: userId,
                            nick: nick,
                            profileImage: profileImage,
                            introduction: introduction)
    }
}

struct PostListResponseDTO: Decodable, Sendable {
    let data: [PostDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent([PostDTO].self, forKey: .data) ?? []
        nextCursor = container.decodeLossyStringIfPresent(forKey: .nextCursor)
    }
}

struct PostFilesResponseDTO: Decodable, Sendable {
    let files: [String]
}

struct LikeToggleResponseDTO: Decodable, Sendable {
    let isLiked: Bool

    enum CodingKeys: String, CodingKey {
        case isLiked = "like_status"
    }
}

struct ReplyDTO: Decodable, Sendable {
    let commentId: String
    let content: String
    let creator: PostCreatorDTO
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case creator
        case createdAt
    }

    init(commentId: String, content: String, creator: PostCreatorDTO, createdAt: String) {
        self.commentId = commentId
        self.content = content
        self.creator = creator
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commentId = container.decodeLossyString(forKey: .commentId)
        content   = try container.decode(String.self, forKey: .content)
        creator   = try container.decode(PostCreatorDTO.self, forKey: .creator)
        createdAt = try container.decode(String.self, forKey: .createdAt)
    }
}

extension ReplyDTO {
    var asUserInfo: UserInfoResponseDTO {
        creator.asUserInfo
    }
}

struct CommentDTO: Decodable, Sendable {
    let commentId: String
    let content: String
    let creator: PostCreatorDTO
    let createdAt: String
    let replies: [ReplyDTO]

    enum CodingKeys: String, CodingKey {
        case commentId = "comment_id"
        case content
        case creator
        case createdAt
        case replies
    }

    init(commentId: String, content: String, creator: PostCreatorDTO, createdAt: String, replies: [ReplyDTO]) {
        self.commentId = commentId
        self.content = content
        self.creator = creator
        self.createdAt = createdAt
        self.replies = replies
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        commentId = container.decodeLossyString(forKey: .commentId)
        content   = try container.decode(String.self, forKey: .content)
        creator   = try container.decode(PostCreatorDTO.self, forKey: .creator)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        replies   = try container.decodeIfPresent([ReplyDTO].self, forKey: .replies) ?? []
    }
}

private extension KeyedDecodingContainer {
    func decodeLossyString(forKey key: Key) -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        return ""
    }

    func decodeLossyStringIfPresent(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }
}
