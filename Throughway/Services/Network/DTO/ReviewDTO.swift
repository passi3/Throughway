//
//  ReviewDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

// MARK: - Request

struct CreateReviewRequestDTO: Encodable, Sendable {
    let rating: Int
    let content: String
    let files: [String]
}

struct UpdateReviewRequestDTO: Encodable, Sendable {
    let rating: Int?
    let content: String?
    let files: [String]?
}

// MARK: - Response

struct ReviewDTO: Decodable, Sendable {
    let reviewId: String
    let rating: Int
    let content: String
    let files: [String]
    let creator: PostCreatorDTO
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case reviewId = "review_id"
        case rating
        case content
        case files
        case creator
        case createdAt = "created_at"
    }
}

struct ReviewListResponseDTO: Decodable, Sendable {
    let data: [ReviewDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}

struct ReviewFilesResponseDTO: Decodable, Sendable {
    let files: [String]
}

/// 별점별 리뷰 개수 (1~5점)
struct ReviewRatingsDTO: Decodable, Sendable {
    let one: Int
    let two: Int
    let three: Int
    let four: Int
    let five: Int
    let average: Double

    enum CodingKeys: String, CodingKey {
        case one     = "1"
        case two     = "2"
        case three   = "3"
        case four    = "4"
        case five    = "5"
        case average
    }
}
