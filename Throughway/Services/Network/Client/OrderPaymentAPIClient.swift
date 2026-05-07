//
//  OrderPaymentAPIClient.swift
//  Throughway
//
//  Created by passi on 4/29/26.
//

import Foundation

struct OrderPaymentAPIClient {
    // Order
    var createOrder:      @Sendable (CreateOrderRequestDTO) async throws -> CreateOrderResponseDTO
    var fetchOrders:      @Sendable () async throws -> OrderListResponseDTO

    // Payment
    var validateReceipt:  @Sendable (PaymentValidationRequestDTO) async throws -> PaymentReceiptDTO
    var fetchReceipt:     @Sendable (String) async throws -> PaymentReceiptDTO
}

extension OrderPaymentAPIClient {
    static let live: OrderPaymentAPIClient = {
        let network = SharedNetwork.manager
        return Self(
            createOrder: { dto in
                try await network.request(OrderRouter.createOrder(dto))
            },
            fetchOrders: {
                try await network.request(OrderRouter.fetchOrders)
            },
            validateReceipt: { dto in
                try await network.request(PaymentRouter.validateReceipt(dto))
            },
            fetchReceipt: { orderCode in
                try await network.request(PaymentRouter.fetchReceipt(orderCode: orderCode))
            }
        )
    }()
}
