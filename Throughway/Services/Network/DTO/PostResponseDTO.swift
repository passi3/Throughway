//
//  PostResponseDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

struct PostDTO: Decodable, Sendable {
    let postId: String
    let country: String?
    let category: String?
    let title: String
    let content: String
    let files: [String]
    let isLike: Bool
    let likeCount: Int
    let creator: PostCreatorDTO
    let activityId: String?
    let geolocation: GeolocationDTO?
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case postId     = "post_id"
        case country
        case category
        case title
        case content
        case files
        case isLike     = "is_like"
        case likeCount  = "like_count"
        case creator
        case activityId = "activity_id"
        case geolocation
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        postId = container.decodeLossyString(forKey: .postId)
        country = try container.decodeIfPresent(String.self, forKey: .country)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        files = try container.decodeIfPresent([String].self, forKey: .files) ?? []
        isLike = try container.decodeIfPresent(Bool.self, forKey: .isLike) ?? false
        likeCount = try container.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        creator = try container.decode(PostCreatorDTO.self, forKey: .creator)
        activityId = container.decodeLossyStringIfPresent(forKey: .activityId)
        geolocation = try container.decodeIfPresent(GeolocationDTO.self, forKey: .geolocation)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
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
