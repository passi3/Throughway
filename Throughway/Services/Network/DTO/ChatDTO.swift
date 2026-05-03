//
//  ChatDTO.swift
//  Throughway
//

import Foundation

// MARK: - Sender

struct ChatSenderDTO: Decodable, Sendable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

// MARK: - Message

struct ChatMessageDTO: Decodable, Sendable, Identifiable {
    var id: String { chatId }

    let chatId: String
    let roomId: String
    let content: String
    let createdAt: String
    let sender: ChatSenderDTO
    let files: [String]

    enum CodingKeys: String, CodingKey {
        case chatId = "chat_id"
        case roomId = "room_id"
        case content
        case createdAt
        case sender
        case files
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chatId    = container.decodeLossyString(forKey: .chatId)
        roomId    = container.decodeLossyString(forKey: .roomId)
        content   = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        createdAt = try container.decode(String.self, forKey: .createdAt)
        sender    = try container.decode(ChatSenderDTO.self, forKey: .sender)
        files     = try container.decodeIfPresent([String].self, forKey: .files) ?? []
    }

    // 소켓 수신용 수동 이니셜라이저
    init(chatId: String, roomId: String, content: String, createdAt: String, sender: ChatSenderDTO, files: [String]) {
        self.chatId = chatId
        self.roomId = roomId
        self.content = content
        self.createdAt = createdAt
        self.sender = sender
        self.files = files
    }
}

// MARK: - Participant

struct ChatParticipantDTO: Decodable, Sendable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage
    }
}

// MARK: - Room

struct ChatRoomDTO: Decodable, Sendable, Identifiable, Hashable {
    var id: String { roomId }

    static func == (lhs: ChatRoomDTO, rhs: ChatRoomDTO) -> Bool { lhs.roomId == rhs.roomId }
    func hash(into hasher: inout Hasher) { hasher.combine(roomId) }

    let roomId: String
    let participants: [ChatParticipantDTO]
    let lastChat: ChatMessageDTO?
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case participants
        case lastChat = "last_chat"
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        roomId       = container.decodeLossyString(forKey: .roomId)
        participants = try container.decodeIfPresent([ChatParticipantDTO].self, forKey: .participants) ?? []
        lastChat     = try container.decodeIfPresent(ChatMessageDTO.self, forKey: .lastChat)
        updatedAt    = try container.decodeIfPresent(String.self, forKey: .updatedAt) ?? ""
    }
}

// MARK: - Response

struct ChatRoomListResponseDTO: Decodable, Sendable {
    let data: [ChatRoomDTO]
}

struct ChatMessageListResponseDTO: Decodable, Sendable {
    let data: [ChatMessageDTO]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent([ChatMessageDTO].self, forKey: .data) ?? []
    }

    enum CodingKeys: String, CodingKey {
        case data
    }
}

// MARK: - Request

struct SendMessageRequestDTO: Encodable {
    let content: String
    let files: [String]
}

// MARK: - Decode Helpers

private extension KeyedDecodingContainer {
    func decodeLossyString(forKey key: Key) -> String {
        if let value = try? decode(String.self, forKey: key) { return value }
        if let value = try? decode(Int.self, forKey: key) { return String(value) }
        if let value = try? decode(Double.self, forKey: key) { return String(value) }
        return ""
    }
}
