//
//  ActivityRouter.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation
import Alamofire

enum ActivityRouter: TargetType {
    
    

    // 인증 필요
    case fetchList(country: String?, category: String?, next: String?, limit: Int?)
    case fetchDetail(activityId: String)
    case fetchNew(country: String?, category: String?)
    case toggleKeep(activityId: String)
    case search(query: String)
    case fetchMyKeeps
    case fetchUserReviews(userId: String)
}

// MARK: - TargetType 구현

extension ActivityRouter {

    var path: String {
        switch self {
        case .fetchList:                     return "/v1/activities"
        case .fetchDetail(let id):           return "/v1/activities/\(id)"
        case .toggleKeep(let id):            return "/v1/activities/\(id)/keep"
        case .fetchNew:                      return "/v1/activities/new"
        case .search:                        return "/v1/activities/search"
        case .fetchMyKeeps:                  return "/v1/activities/keeps/me"
        case .fetchUserReviews(let userId):  return "/v1/activities/reviews/users/\(userId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .toggleKeep:
            return .post
        case .fetchList, .fetchNew, .fetchDetail, .search, .fetchMyKeeps, .fetchUserReviews:
            return .get
        }
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

    var queryItems: [URLQueryItem]? {
        switch self {
        case .fetchList(let country, let category, let next, let limit):
            var items: [URLQueryItem] = []
            if let country  { items.append(URLQueryItem(name: "country",  value: country))  }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            if let next     { items.append(URLQueryItem(name: "next",     value: next))     }
            if let limit    { items.append(URLQueryItem(name: "limit",    value: "\(limit)")) }
            return items.isEmpty ? nil : items

        case .fetchNew(let country, let category):
            var items: [URLQueryItem] = []
            if let country  { items.append(URLQueryItem(name: "country",  value: country)) }
            if let category { items.append(URLQueryItem(name: "category", value: category)) }
            return items.isEmpty ? nil : items

        case .search(let query):
            return [URLQueryItem(name: "title", value: query)]

        default:
            return nil
        }
    }
}
