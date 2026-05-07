//
//  OrderDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

// MARK: - Request

struct CreateOrderRequestDTO: Encodable, Sendable {
    let activityId: String
    let reservationItemName: String   // 예약 날짜 (ex. "2026-05-07")
    let reservationItemTime: String   // 예약 시간 (ex. "10:00")
    let participantCount: Int         // 참가 인원 수
    let totalPrice: Int               // final_price × participant_count

    enum CodingKeys: String, CodingKey {
        case activityId          = "activity_id"
        case reservationItemName = "reservation_item_name"
        case reservationItemTime = "reservation_item_time"
        case participantCount    = "participant_count"
        case totalPrice          = "total_price"
    }
}

// MARK: - Create Response (POST /v1/orders)

struct CreateOrderResponseDTO: Decodable, Sendable {
    let orderId: String
    let orderCode: String   // Portone merchant_uid로 사용
    let totalPrice: Int
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId    = "order_id"
        case orderCode  = "order_code"
        case totalPrice = "total_price"
        case createdAt
        case updatedAt
    }
}

// MARK: - List Item (POST /v1/orders)

struct OrderReviewSummaryDTO: Decodable, Sendable {
    let reviewId: String
    let rating: Int

    enum CodingKeys: String, CodingKey {
        case reviewId = "review_id"
        case rating
    }
}

struct OrderActivityDTO: Decodable, Sendable {
    let activityId: String
    let title: String
    let category: String
    let country: String
    let thumbnails: [String]
    let price: ActivityPriceDTO
    let pointReward: Int

    enum CodingKeys: String, CodingKey {
        case activityId  = "id"
        case title, category, country, thumbnails, price
        case pointReward = "point_reward"
    }
}

struct OrderDTO: Decodable, Sendable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let review: OrderReviewSummaryDTO?
    let reservationItemName: String?
    let reservationItemTime: String?
    let participantCount: Int
    let activity: OrderActivityDTO
    let paidAt: String
    let createdAt: String
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case orderId             = "order_id"
        case orderCode           = "order_code"
        case totalPrice          = "total_price"
        case review
        case reservationItemName = "reservation_item_name"
        case reservationItemTime = "reservation_item_time"
        case participantCount    = "participant_count"
        case activity
        case paidAt
        case createdAt
        case updatedAt
    }
}

struct OrderListResponseDTO: Decodable, Sendable {
    let data: [OrderDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }
}
