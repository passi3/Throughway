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
            SocketIOManager.shared.disconnectSingle()

        case .inputChanged(let text):
            reduce { $0.inputText = text }

        case .sendTapped:
            sendMessage()

        case .dismissProfileUpdate:
            reduce { $0.updatedOpponentProfile = nil }

        case .filesPicked(let results):
            handleFilesPicked(results)

        case .removePendingFile(let id):
            reduce { $0.pendingFiles.removeAll { $0.id == id } }

        case .retryPending(let id):
            guard let pending = state.pendingMessages.first(where: { $0.id == id }),
                  pending.isFailed else { return }
            reduce { s in
                if let i = s.pendingMessages.firstIndex(where: { $0.id == id }) {
                    s.pendingMessages[i].isFailed = false
                }
            }
            Task { await _doSend(pending) }

        case .deletePending(let id):
            reduce { $0.pendingMessages.removeAll { $0.id == id } }

        case .dismissSendFailedAlert:
            reduce { $0.showSendFailedAlert = false }

        case .dismissEmptyTextAlert:
            reduce { $0.showEmptyTextAlert = false }
        }
    }

    // MARK: - Bootstrap: 로컬 DB → 서버 동기화 → 소켓 연결

    private func bootstrap() async {
        checkProfileUpdate()

        let local = chatRepo.fetchMessages(roomId: room.roomId)
        reduce { $0.messages = local }

        let lastSeen = chatRepo.lastSeenAt(roomId: room.roomId)

        if lastSeen != nil {
            reduce { $0.isLoadingHistory = true }
            defer { reduce { $0.isLoadingHistory = false } }

            do {
                let cursor = chatRepo.lastMessageDate(roomId: room.roomId) ?? lastSeen
                let response = try await chatClient.fetchMessages(room.roomId, cursor)
                if !response.data.isEmpty {
                    chatRepo.save(messages: response.data)
                    let updated = chatRepo.fetchMessages(roomId: room.roomId)
                    reduce { $0.messages = updated }
                }
            } catch {
                print("[ChatDetail] fetchMessages error:", error)
            }
        }

        chatRepo.updateLastSeen(roomId: room.roomId)

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
        for await message in SocketIOManager.shared.messageStream() {
            guard !Task.isCancelled else { break }
            guard message.roomId == room.roomId else { continue }
            guard !state.messages.contains(where: { $0.chatId == message.chatId }) else { continue }
            chatRepo.save(message: message)
            reduce { $0.messages.append(message) }
        }
    }

    // MARK: - 파일 선택 처리

    private func handleFilesPicked(_ results: [PendingFilePickResult]) {
        let remaining = max(0, 5 - state.pendingFiles.count)
        guard remaining > 0 else { return }
        let newFiles: [PendingFile] = results.prefix(remaining).compactMap { r in
            guard r.data.count <= 5 * 1024 * 1024 else { return nil }
            return PendingFile(id: UUID(), data: r.data, fileName: r.fileName, mimeType: Self.mimeType(for: r.ext))
        }
        reduce { $0.pendingFiles.append(contentsOf: newFiles) }
    }

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "jpg", "jpeg": return "image/jpeg"
        case "png":         return "image/png"
        case "gif":         return "image/gif"
        case "pdf":         return "application/pdf"
        default:            return "application/octet-stream"
        }
    }

    // MARK: - 채팅 전송

    private func sendMessage() {
        let content = state.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            if !state.pendingFiles.isEmpty {
                reduce { $0.showEmptyTextAlert = true }
            }
            return
        }

        let files = state.pendingFiles
        let pending = PendingMessage(id: UUID(), content: content, files: files)

        reduce {
            $0.inputText = ""
            $0.pendingFiles = []
            $0.pendingMessages.append(pending)
        }
        Task { await _doSend(pending) }
    }

    @MainActor
    private func _doSend(_ pending: PendingMessage) async {
        do {
            var fileURLs: [String] = []
            if !pending.files.isEmpty {
                let response = try await chatClient.uploadFiles(room.roomId, pending.files)
                fileURLs = response.files
            }
            let dto = SendMessageRequestDTO(content: pending.content, files: fileURLs)
            let sent = try await chatClient.sendMessage(room.roomId, dto)
            reduce { $0.pendingMessages.removeAll { $0.id == pending.id } }
            if !state.messages.contains(where: { $0.chatId == sent.chatId }) {
                chatRepo.save(message: sent)
                reduce { $0.messages.append(sent) }
            }
        } catch {
            print("[ChatDetail] sendMessage error:", error)
            reduce { s in
                if let i = s.pendingMessages.firstIndex(where: { $0.id == pending.id }) {
                    s.pendingMessages[i].isFailed = true
                }
                s.showSendFailedAlert = true
            }
        }
    }
}
