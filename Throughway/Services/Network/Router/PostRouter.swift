//
//  PostRouter.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation
import Alamofire

enum PostRouter: TargetType {
    case uploadFiles([Data])
    case createPost(CreatePostRequestDTO)
    case fetchByGeolocation(latitude: Double, longitude: Double, distance: Int, next: String?, limit: Int?)
    case searchByTitle(query: String)
    case fetchDetail(postId: String)
    case updatePost(postId: String, UpdatePostRequestDTO)
    case deletePost(postId: String)
    case toggleLike(postId: String, body: LikeToggleRequestDTO)
    case fetchUserPosts(userId: String)
    case fetchMyLikedPosts
    case createComment(postId: String, body: CreateCommentRequestDTO)
    case deleteComment(postId: String, commentId: String)
    case updateComment(postId: String, commentId: String, body: UpdateCommentRequestDTO)
}

// MARK: - TargetType 구현

extension PostRouter {

    var path: String {
        switch self {
        case .uploadFiles:              return "/v1/posts/files"
        case .createPost:               return "/v1/posts"
        case .fetchByGeolocation:       return "/v1/posts/geolocation"
        case .searchByTitle:            return "/v1/posts/search"
        case .fetchDetail(let id):              return "/v1/posts/\(id)"
        case .updatePost(let id, _):            return "/v1/posts/\(id)"
        case .deletePost(let id):               return "/v1/posts/\(id)"
        case .toggleLike(let id, _):            return "/v1/posts/\(id)/like"
        case .fetchUserPosts(let id):           return "/v1/posts/users/\(id)"
        case .fetchMyLikedPosts:                return "/v1/posts/likes/me"
        case .createComment(let id, _):                     return "/v1/posts/\(id)/comments"
        case .deleteComment(let id, let cid):               return "/v1/posts/\(id)/comments/\(cid)"
        case .updateComment(let id, let cid, _):            return "/v1/posts/\(id)/comments/\(cid)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .uploadFiles, .createPost, .toggleLike, .createComment:
            return .post
        case .updatePost, .updateComment:
            return .put
        case .deletePost, .deleteComment:
            return .delete
        case .fetchByGeolocation, .searchByTitle, .fetchDetail, .fetchUserPosts, .fetchMyLikedPosts:
            return .get
        }
    }

    var headers: [String: String] {
        defaultHeaders
    }

    var body: RequestBody {
        switch self {
        case .createPost(let dto):
            return .json(dto)
        case .updatePost(_, let dto):
            return .json(dto)
        case .toggleLike(_, let body):
            return .json(body)
        case .createComment(_, let body):
            return .json(body)
        case .updateComment(_, _, let body):
            return .json(body)
        case .uploadFiles(let dataList):
            let parts = dataList.enumerated().map { index, data in
                MultipartBody.Part(
                    name: "files",
                    data: data,
                    fileName: "file_\(index).jpg",
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

    var queryItems: [URLQueryItem]? {
        switch self {
        case .fetchByGeolocation(let lat, let lon, let distance, let next, let limit):
            var items: [URLQueryItem] = [
                URLQueryItem(name: "latitude",  value: "\(lat)"),
                URLQueryItem(name: "longitude", value: "\(lon)"),
                URLQueryItem(name: "distance",  value: "\(distance)")
            ]
            if let next  { items.append(URLQueryItem(name: "next",  value: next)) }
            if let limit { items.append(URLQueryItem(name: "limit", value: "\(limit)")) }
            return items
        case .searchByTitle(let query):
            return [URLQueryItem(name: "title", value: query)]
        default:
            return nil
        }
    }
}
