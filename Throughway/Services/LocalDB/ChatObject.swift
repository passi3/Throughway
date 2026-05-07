//
//  ChatObject.swift
//  Throughway
//
//  Created by passi on 5/3/26.
//

import Foundation
import RealmSwift

final class ChatMessageObject: Object {
    @Persisted(primaryKey: true) var chatId: String
    @Persisted var roomId: String
    @Persisted var content: String
    @Persisted var createdAt: String
    @Persisted var senderUserId: String
    @Persisted var senderNick: String
    @Persisted var senderProfileImage: String?
    @Persisted var files: List<String>
}

extension ChatMessageObject {
    func toDTO() -> ChatMessageDTO {
        let sender = ChatSenderDTO(
            userId: senderUserId,
            nick: senderNick,
            profileImage: senderProfileImage
        )
        return ChatMessageDTO(
            chatId: chatId,
            roomId: roomId,
            content: content,
            createdAt: createdAt,
            sender: sender,
            files: Array(files)
        )
    }
}

// MARK: - 채팅방 마지막 진입 시점 기록

final class ChatRoomLastSeenRecord: Object {
    @Persisted(primaryKey: true) var roomId: String
    @Persisted var lastSeenAt: String
}

extension ChatMessageDTO {
    func toObject() -> ChatMessageObject {
        let object = ChatMessageObject()
        object.chatId = chatId
        object.roomId = roomId
        object.content = content
        object.createdAt = createdAt
        object.senderUserId = sender.userId
        object.senderNick = sender.nick
        object.senderProfileImage = sender.profileImage
        object.files.append(objectsIn: files)
        return object
    }
}
