//
//  PaymentRouter.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation
import Alamofire

enum PaymentRouter: TargetType {
    case validateReceipt(PaymentValidationRequestDTO)
    case fetchReceipt(orderCode: String)
}

extension PaymentRouter {

    var path: String {
        switch self {
        case .validateReceipt:             return "/v1/payments/validation"
        case .fetchReceipt(let orderCode): return "/v1/payments/\(orderCode)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .validateReceipt:  return .post
        case .fetchReceipt:     return .get
        }
    }

    var headers: [String: String] {
        defaultHeaders
    }

    var body: RequestBody {
        switch self {
        case .validateReceipt(let dto):  return .json(dto)
        case .fetchReceipt:              return .none
        }
    }

    var requiresAuthorization: Bool {
        true
    }
}
