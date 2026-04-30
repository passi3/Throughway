//
//  PaymentDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

// MARK: - Request

struct PaymentValidationRequestDTO: Encodable, Sendable {
    let impUid: String
    let merchantUid: String

    enum CodingKeys: String, CodingKey {
        case impUid      = "imp_uid"
        case merchantUid = "merchant_uid"
    }
}

// MARK: - Response

struct PaymentReceiptDTO: Decodable, Sendable {
    let orderCode: String
    let status: String
    let amount: Int
    let paidAt: String?

    enum CodingKeys: String, CodingKey {
        case orderCode = "order_code"
        case status
        case amount
        case paidAt    = "paid_at"
    }
}
