//
//  PaymentDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

// MARK: - Request

/// /v1/payments/validation 요청 바디
/// 서버가 imp_uid로 포트원에서 merchant_uid(=order_code)를 직접 조회해 검증한다.
struct PaymentValidationRequestDTO: Encodable, Sendable {
    let impUid: String

    enum CodingKeys: String, CodingKey {
        case impUid = "imp_uid"
    }
}

// MARK: - Response

/// /v1/payments/validation 응답 전체
struct PaymentReceiptDTO: Decodable, Sendable {
    let paymentId: String
    let orderItem: PaymentOrderItemDTO
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case paymentId = "payment_id"
        case orderItem = "order_item"
        case createdAt
        case updatedAt
    }
}

/// order_item 내부 구조
struct PaymentOrderItemDTO: Decodable, Sendable {
    let orderId: String
    let orderCode: String
    let totalPrice: Int
    let reservationItemName: String
    let reservationItemTime: String
    let participantCount: Int
    let activity: PaymentActivityDTO
    let paidAt: String?
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case orderId             = "order_id"
        case orderCode           = "order_code"
        case totalPrice          = "total_price"
        case reservationItemName = "reservation_item_name"
        case reservationItemTime = "reservation_item_time"
        case participantCount    = "participant_count"
        case activity
        case paidAt
        case createdAt
        case updatedAt
    }
}

/// order_item.activity — 목록용 ActivitySummaryDTO와 다르게 id 키를 사용
struct PaymentActivityDTO: Decodable, Sendable {
    let id: String
    let title: String
    let country: String
    let category: String
    let thumbnails: [String]
    let geolocation: GeolocationDTO
    let price: ActivityPriceDTO
    let tags: [String]
    let pointReward: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case country
        case category
        case thumbnails
        case geolocation
        case price
        case tags
        case pointReward = "point_reward"
    }
}
