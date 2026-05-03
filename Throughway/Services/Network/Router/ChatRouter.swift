//
//  ChatRouter.swift
//  Throughway
//

import Foundation
import Alamofire

enum ChatRouter: TargetType {
    case fetchRooms
    case createOrGetRoom(opponentId: String)
    case fetchMessages(roomId: String, cursorDate: String?)
    case sendMessage(roomId: String, body: SendMessageRequestDTO)
}

extension ChatRouter {

    var path: String {
        switch self {
        case .fetchRooms:
            return "/v1/chats"
        case .createOrGetRoom(let opponentId):
            return "/v1/chats/\(opponentId)"
        case .fetchMessages(let roomId, _):
            return "/v1/chats/\(roomId)"
        case .sendMessage(let roomId, _):
            return "/v1/chats/\(roomId)"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchRooms, .fetchMessages:
            return .get
        case .createOrGetRoom, .sendMessage:
            return .post
        }
    }

    var body: RequestBody {
        switch self {
        case .sendMessage(_, let dto):
            return .json(dto)
        default:
            return .none
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .fetchMessages(_, let cursorDate):
            guard let cursorDate else { return nil }
            return [URLQueryItem(name: "cursor_date", value: cursorDate)]
        default:
            return nil
        }
    }

    var requiresAuthorization: Bool { true }

    var headers: [String: String] { defaultHeaders }
}
