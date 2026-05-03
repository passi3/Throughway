//
//  SocketIOManager.swift
//  Throughway
//

import Foundation
import SocketIO

@MainActor
final class SocketIOManager {
    static let shared = SocketIOManager()

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var messageContinuation: AsyncStream<ChatMessageDTO>.Continuation?

    private(set) var incomingMessages: AsyncStream<ChatMessageDTO>

    private init() {
        var continuation: AsyncStream<ChatMessageDTO>.Continuation!
        incomingMessages = AsyncStream { continuation = $0 }
        messageContinuation = continuation
    }

    // MARK: - Connect

    func connect(roomId: String, token: String) {
        disconnect()

        guard let baseURL = URL(string: Activity.url) else { return }

        let namespace = "/chats-\(roomId)"

        manager = SocketManager(
            socketURL: baseURL,
            config: [
                .log(false),
                .compress,
                .extraHeaders([
                    "SeSACKey": Activity.key,
                    "Authorization": token
                ])
            ]
        )

        socket = manager?.socket(forNamespace: namespace)
        registerHandlers()
        socket?.connect()
    }

    // MARK: - Disconnect

    func disconnect() {
        socket?.disconnect()
        socket = nil
        manager = nil
    }

    // MARK: - Handlers

    private func registerHandlers() {
        socket?.on(clientEvent: .connect) { data, _ in
            print("[Socket] Connected", data)
        }

        socket?.on(clientEvent: .disconnect) { data, _ in
            print("[Socket] Disconnected", data)
        }

        socket?.on(clientEvent: .error) { data, _ in
            print("[Socket] Error", data)
        }

        socket?.on("chat") { [weak self] dataArray, _ in
            guard let self,
                  let dict = dataArray.first as? [String: Any],
                  let message = ChatMessageDTO(socketPayload: dict) else { return }
            self.messageContinuation?.yield(message)
        }
    }
}

// MARK: - Socket Payload Parsing

private extension ChatMessageDTO {
    init?(socketPayload dict: [String: Any]) {
        guard
            let chatId    = dict["chat_id"] as? String,
            let roomId    = dict["room_id"] as? String,
            let createdAt = dict["createdAt"] as? String,
            let senderDict = dict["sender"] as? [String: Any],
            let userId    = senderDict["user_id"] as? String,
            let nick      = senderDict["nick"] as? String
        else { return nil }

        let content = dict["content"] as? String ?? ""
        let files   = dict["files"] as? [String] ?? []
        let profileImage = senderDict["profileImage"] as? String

        let sender = ChatSenderDTO(userId: userId, nick: nick, profileImage: profileImage)
        self.init(chatId: chatId, roomId: roomId, content: content, createdAt: createdAt, sender: sender, files: files)
    }
}
