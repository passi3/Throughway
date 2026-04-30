//
//  TargetType.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation
import Alamofire

typealias HTTPMethod = Alamofire.HTTPMethod

enum RequestBody {
    case json(Encodable)
    case multipart(MultipartBody)
    case none
}

struct MultipartBody {
    struct Part {
        let name: String
        let data: Data
        let fileName: String?
        let mimeType: String
    }
    var parts: [Part]
}

protocol TargetType {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: RequestBody { get }
    var queryItems: [URLQueryItem]? { get }
    var requiresAuthorization: Bool { get }
}

// MARK: - Default

extension TargetType {
    var baseURL: String { APIConstants.baseURL }
    var queryItems: [URLQueryItem]? { nil }
    var requiresAuthorization: Bool { false }

    var defaultHeaders: [String: String] {
        [
            "accept": "application/json",
            "Content-Type": "application/json",
            "SeSACKey": APIConstants.sesacKey
        ]
    }
}

// MARK: - Constants

enum APIConstants {
    static let baseURL = Activity.url
    static let sesacKey = Activity.key
}
