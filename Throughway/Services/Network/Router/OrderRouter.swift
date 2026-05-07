//
//  OrderRouter.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation
import Alamofire

enum OrderRouter: TargetType {
    case createOrder(CreateOrderRequestDTO)
    case fetchOrders
}

extension OrderRouter {

    var path: String {
        "/v1/orders"
    }

    var method: HTTPMethod {
        switch self {
        case .createOrder:  return .post
        case .fetchOrders:  return .post
        }
    }

    var headers: [String: String] {
        defaultHeaders
    }

    var body: RequestBody {
        switch self {
        case .createOrder(let dto):  return .json(dto)
        case .fetchOrders:           return .none
        }
    }

    var requiresAuthorization: Bool {
        true
    }
}
