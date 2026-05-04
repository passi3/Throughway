//
//  ChatAPIClient.swift
//  Throughway
//
//  Created by passi on 5/4/26.
//

import Foundation

struct ChatAPIClient {
    var fetchRooms:      @Sendable () async throws -> ChatRoomListResponseDTO
    var createOrGetRoom: @Sendable (_ opponentId: String) async throws -> ChatRoomDTO
    var fetchMessages:   @Sendable (_ roomId: String, _ cursorDate: String?) async throws -> ChatMessageListResponseDTO
    var sendMessage:     @Sendable (_ roomId: String, _ body: SendMessageRequestDTO) async throws -> ChatMessageDTO
    var uploadFiles:     @Sendable (_ roomId: String, _ files: [PendingFile]) async throws -> ChatUploadFilesResponseDTO
}

extension ChatAPIClient {
    static let live: ChatAPIClient = {
        let network = SharedNetwork.manager
        return Self(
            fetchRooms: {
                try await network.request(ChatRouter.fetchRooms)
            },
            createOrGetRoom: { opponentId in
                try await network.request(ChatRouter.createOrGetRoom(.init(opponentId: opponentId)))
            },
            fetchMessages: { roomId, cursorDate in
                try await network.request(ChatRouter.fetchMessages(roomId: roomId, cursorDate: cursorDate))
            },
            sendMessage: { roomId, body in
                try await network.request(ChatRouter.sendMessage(roomId: roomId, body: body))
            },
            uploadFiles: { roomId, files in
                let parts = files.map { (data: $0.data, fileName: $0.fileName, mimeType: $0.mimeType) }
                return try await network.request(ChatRouter.uploadFiles(roomId: roomId, parts: parts))
            }
        )
    }()
}
