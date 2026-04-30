//
//  ReviewRouter.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation
import Alamofire

enum ReviewRouter: TargetType {
    case uploadFiles(activityId: String, [Data])
    case createReview(activityId: String, CreateReviewRequestDTO)
    case fetchList(activityId: String)
    case fetchDetail(activityId: String, reviewId: String)
    case updateReview(activityId: String, reviewId: String, UpdateReviewRequestDTO)
    case deleteReview(activityId: String, reviewId: String)
    case fetchRatings(activityId: String)
}

// MARK: - TargetType 구현

extension ReviewRouter {

    var path: String {
        switch self {
        case .uploadFiles(let id, _):
            return "/v1/activities/\(id)/reviews/files"
        case .createReview(let id, _):
            return "/v1/activities/\(id)/reviews"
        case .fetchList(let id):
            return "/v1/activities/\(id)/reviews"
        case .fetchDetail(let aid, let rid):
            return "/v1/activities/\(aid)/reviews/\(rid)"
        case .updateReview(let aid, let rid, _):
            return "/v1/activities/\(aid)/reviews/\(rid)"
        case .deleteReview(let aid, let rid):
            return "/v1/activities/\(aid)/reviews/\(rid)"
        case .fetchRatings(let id):
            return "/v1/activities/\(id)/reviews/reviews-ratings"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .uploadFiles, .createReview:
            return .post
        case .updateReview:
            return .put
        case .deleteReview:
            return .delete
        case .fetchList, .fetchDetail, .fetchRatings:
            return .get
        }
    }

    var headers: [String: String] {
        defaultHeaders
    }

    var body: RequestBody {
        switch self {
        case .createReview(_, let dto):
            return .json(dto)
        case .updateReview(_, _, let dto):
            return .json(dto)
        case .uploadFiles(_, let dataList):
            let parts = dataList.enumerated().map { index, data in
                MultipartBody.Part(
                    name: "files",
                    data: data,
                    fileName: "review_\(index).jpg",
                    mimeType: "image/jpeg"
                )
            }
            return .multipart(MultipartBody(parts: parts))
        default:
            return .none
        }
    }

    var requiresAuthorization: Bool {
        true
    }
}
