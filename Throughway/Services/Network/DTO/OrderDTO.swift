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
    let scheduleDate: String
    let scheduleTime: String

    enum CodingKeys: String, CodingKey {
        case activityId   = "activity_id"
        case scheduleDate = "schedule_date"
        case scheduleTime = "schedule_time"
    }
}

// MARK: - Response

struct OrderDTO: Decodable, Sendable {
    let orderCode: String
    let activityId: String
    let status: String
    let price: Int
    let scheduleDate: String?
    let scheduleTime: String?
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case orderCode    = "order_code"
        case activityId   = "activity_id"
        case status
        case price
        case scheduleDate = "schedule_date"
        case scheduleTime = "schedule_time"
        case createdAt    = "created_at"
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
