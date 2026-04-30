//
//  BannerRouter.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation
import Alamofire

enum BannerRouter: TargetType {
    case fetchMain
}

extension BannerRouter {

    var path: String {
        "/v1/banners/main"
    }

    var method: HTTPMethod {
        .get
    }

    var headers: [String: String] {
        defaultHeaders
    }

    var body: RequestBody {
        .none
    }

    var requiresAuthorization: Bool {
        true
    }
}
