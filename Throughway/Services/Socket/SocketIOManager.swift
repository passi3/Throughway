//
//  SocketIOManager.swift
//  Throughway
//
//  Created by passi on 5/4/26.
//

import Foundation
import SocketIO

@MainActor
final class SocketIOManager {
    static let shared = SocketIOManager()

    private var manager: SocketManager?
    private var socket: SocketIOClient?
    private var sockets: [SocketIOClient] = []

    /// 브로드캐스트: 여러 소비자가 동시에 메시지를 받을 수 있도록 continuation 목록 관리
    private var continuations: [UUID: AsyncStream<ChatMessageDTO>.Continuation] = [:]

    private init() {}

    // MARK: - Stream (broadcast)

    /// 호출할 때마다 독립적인 AsyncStream을 반환. 각 소비자가 모든 메시지를 받음.
    func messageStream() -> AsyncStream<ChatMessageDTO> {
        let id = UUID()
        return AsyncStream { continuation in
            self.continuations[id] = continuation
            continuation.onTermination = { _ in
                Task { @MainActor in
                    self.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - Connect (single room — ChatDetail용)

    func connect(roomId: String, token: String) {
        disconnectSingle()

        guard let baseURL = URL(string: Activity.url) else { return }

        // connectAll로 이미 SocketManager가 있으면 재사용
        if manager == nil {
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
        }

        socket = manager?.socket(forNamespace: "/chats-\(roomId)")
        registerHandlers(on: socket!)
        socket?.connect()
    }

    // MARK: - Connect All (ChatList용)

    func connectAll(roomIds: [String], token: String) {
        disconnect()
        guard !roomIds.isEmpty, let baseURL = URL(string: Activity.url) else { return }

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

        sockets = roomIds.map { roomId in
            let s = manager!.socket(forNamespace: "/chats-\(roomId)")
            registerHandlers(on: s)
            s.connect()
            return s
        }
    }

    // MARK: - Disconnect

    /// 단일 소켓만 해제 (ChatDetail pop 시)
    func disconnectSingle() {
        socket?.disconnect()
        socket = nil
    }

    /// 전체 해제 (ChatList onDisappear / 로그아웃 시)
    func disconnect() {
        socket?.disconnect()
        socket = nil
        sockets.forEach { $0.disconnect() }
        sockets = []
        manager = nil
    }

    // MARK: - Handlers

    private func registerHandlers(on socket: SocketIOClient) {
        socket.on(clientEvent: .connect) { data, _ in
            print("[Socket] Connected", data)
        }
        

        socket.on(clientEvent: .disconnect) { data, _ in
            print("[Socket] Disconnected", data)
        }

        socket.on(clientEvent: .error) { data, _ in
            print("[Socket] Error", data)
        }

        socket.on("chat") { [weak self] dataArray, _ in
            guard let self,
                  let dict = dataArray.first as? [String: Any],
                  let message = ChatMessageDTO(socketPayload: dict) else { return }
            for continuation in self.continuations.values {
                continuation.yield(message)
            }
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
