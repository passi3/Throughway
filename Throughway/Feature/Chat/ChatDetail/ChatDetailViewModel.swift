//
//  ChatDetailViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class ChatDetailViewModel: BaseViewModel<ChatDetailFeature.State, ChatDetailFeature.Intent> {

    private let chatClient: ChatAPIClient
    private let tokenClient: TokenClient
    private let chatRepo: ChatRepository

    private let room: ChatRoomDTO
    private var listenTask: Task<Void, Never>?

    init(
        room: ChatRoomDTO,
        myUserId: String,
        chatClient: ChatAPIClient = .live,
        tokenClient: TokenClient = .live
    ) {
        self.room = room
        self.chatClient = chatClient
        self.tokenClient = tokenClient
        self.chatRepo = ChatRepository()
        super.init(initialState: .init(myUserId: myUserId))
    }

    override func send(_ intent: ChatDetailFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await bootstrap() }

        case .onDisappear:
            listenTask?.cancel()
            SocketIOManager.shared.disconnect()

        case .inputChanged(let text):
            reduce { $0.inputText = text }

        case .sendTapped:
            Task { await sendMessage() }

        case .dismissProfileUpdate:
            reduce { $0.updatedOpponentProfile = nil }
        }
    }

    // MARK: - Bootstrap: 로컬 DB → 서버 동기화 → 소켓 연결

    private func bootstrap() async {
        // 0. 프로필 변경 감지
        checkProfileUpdate()

        // 1. 로컬 DB 조회
        let local = chatRepo.fetchMessages(roomId: room.roomId)
        reduce { $0.messages = local }

        // 2. 서버 동기화
        reduce { $0.isLoadingHistory = true }
        defer { reduce { $0.isLoadingHistory = false } }

        do {
            let cursor = chatRepo.lastMessageDate(roomId: room.roomId)
            let response = try await chatClient.fetchMessages(room.roomId, cursor)
            if !response.data.isEmpty {
                chatRepo.save(messages: response.data)
                let updated = chatRepo.fetchMessages(roomId: room.roomId)
                reduce { $0.messages = updated }
            }
        } catch {
            print("[ChatDetail] fetchMessages error:", error)
        }

        // 3. 소켓 연결 (동기화 완료 후)
        let token = await tokenClient.loadAccessToken() ?? ""
        SocketIOManager.shared.connect(roomId: room.roomId, token: token)
        listenTask = Task { await listenForMessages() }
    }

    // MARK: - 프로필 변경 감지

    private func checkProfileUpdate() {
        guard let opponent = room.participants.first(where: { $0.userId != state.myUserId }) else { return }
        let cacheKey = "profileImage_\(opponent.userId)"
        let currentImage = opponent.profileImage ?? ""
        let cachedImage = UserDefaults.standard.string(forKey: cacheKey)

        if let cachedImage, cachedImage != currentImage {
            reduce { $0.updatedOpponentProfile = opponent }
        }
        UserDefaults.standard.set(currentImage, forKey: cacheKey)
    }

    // MARK: - 실시간 메시지 수신

    private func listenForMessages() async {
        for await message in SocketIOManager.shared.incomingMessages {
            guard !Task.isCancelled else { break }
            guard message.roomId == room.roomId else { continue }
            guard !state.messages.contains(where: { $0.chatId == message.chatId }) else { continue }
            chatRepo.save(message: message)
            reduce { $0.messages.append(message) }
        }
    }

    // MARK: - 채팅 전송

    private func sendMessage() async {
        let content = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !state.isSending else { return }

        reduce { $0.inputText = "" }
        reduce { $0.isSending = true }
        defer { reduce { $0.isSending = false } }

        do {
            let dto = SendMessageRequestDTO(content: content, files: [])
            let sent = try await chatClient.sendMessage(room.roomId, dto)
            // 소켓 echo와 중복되지 않으면 추가
            if !state.messages.contains(where: { $0.chatId == sent.chatId }) {
                chatRepo.save(message: sent)
                reduce { $0.messages.append(sent) }
            }
        } catch {
            print("[ChatDetail] sendMessage error:", error)
            reduce { $0.inputText = content }
        }
    }
}
