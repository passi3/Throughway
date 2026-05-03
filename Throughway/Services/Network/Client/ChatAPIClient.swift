//
//  ChatAPIClient.swift
//  Throughway
//

import Foundation

struct ChatAPIClient {
    var fetchRooms:      @Sendable () async throws -> ChatRoomListResponseDTO
    var createOrGetRoom: @Sendable (_ opponentId: String) async throws -> ChatRoomDTO
    var fetchMessages:   @Sendable (_ roomId: String, _ cursorDate: String?) async throws -> ChatMessageListResponseDTO
    var sendMessage:     @Sendable (_ roomId: String, _ body: SendMessageRequestDTO) async throws -> ChatMessageDTO
}

extension ChatAPIClient {
    static let live: ChatAPIClient = {
        let network = SharedNetwork.manager
        return Self(
            fetchRooms: {
                try await network.request(ChatRouter.fetchRooms)
            },
            createOrGetRoom: { opponentId in
                try await network.request(ChatRouter.createOrGetRoom(opponentId: opponentId))
            },
            fetchMessages: { roomId, cursorDate in
                try await network.request(ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate))
            },
            sendMessage: { roomId, body in
                try await network.request(ChatRouter.sendMessage(roomId: roomId, body: body))
            }
        )
    }()
}
