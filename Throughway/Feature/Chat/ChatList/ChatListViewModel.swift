//
//  ChatListViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class ChatListViewModel: BaseViewModel<ChatListFeature.State, ChatListFeature.Intent> {

    private let chatClient: ChatAPIClient
    private let tokenClient: TokenClient
    private let userClient: UserAPIClient
    private let chatRepo = ChatRepository()
    private var listenTask: Task<Void, Never>?

    init(
        chatClient: ChatAPIClient = .live,
        tokenClient: TokenClient = .live,
        userClient: UserAPIClient = .live
    ) {
        self.chatClient = chatClient
        self.tokenClient = tokenClient
        self.userClient = userClient
        super.init(initialState: .init())
    }

    override func send(_ intent: ChatListFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await loadMyUserId() }
            Task { await fetchRoomsAndConnect() }

        case .onDisappear:
            listenTask?.cancel()
            listenTask = nil
            SocketIOManager.shared.disconnect()

        case .refresh:
            listenTask?.cancel()
            listenTask = nil
            Task { await fetchRoomsAndConnect() }

        case .roomTapped(let room):
            reduce { $0.selectedRoom = room }

        case .clearSelection:
            reduce { $0.selectedRoom = nil }

        case .openRoom(let roomId):
            Task { await openRoom(roomId: roomId) }
        }
    }

    private func loadMyUserId() async {
        guard state.myUserId.isEmpty else { return }
        if let cached = UserDefaults.standard.string(forKey: "myUserId"), !cached.isEmpty {
            reduce { $0.myUserId = cached }
            return
        }
        do {
            let profile = try await userClient.fetchMyProfile()
            UserDefaults.standard.set(profile.userId, forKey: "myUserId")
            reduce { $0.myUserId = profile.userId }
        } catch {
            print("[ChatList] loadMyUserId error:", error)
        }
    }

    private func fetchRoomsAndConnect() async {
        reduce { $0.isLoading = true }
        defer { reduce { $0.isLoading = false } }
        do {
            let response = try await chatClient.fetchRooms()
            let sorted = response.data.sorted { $0.updatedAt > $1.updatedAt }
            var localMap: [String: ChatMessageDTO] = [:]
            for room in sorted {
                if let msg = chatRepo.lastMessage(roomId: room.roomId) {
                    localMap[room.roomId] = msg
                }
            }
            reduce {
                $0.rooms = sorted
                $0.roomLastMessages = localMap
            }

            // 딥링크 pending 처리: fetchRooms 완료 후 네비게이션
            if let roomId = state.pendingDeepLinkRoomId,
               let room = sorted.first(where: { $0.roomId == roomId }) {
                reduce {
                    $0.pendingDeepLinkRoomId = nil
                    $0.selectedRoom = room
                }
            }

            let roomIds = sorted.map { $0.roomId }
            let token = await tokenClient.loadAccessToken() ?? ""
            SocketIOManager.shared.connectAll(roomIds: roomIds, token: token)
            listenTask = Task { await listenForMessages() }
        } catch {
            print("[ChatList] fetchRooms error:", error)
        }
    }

    private func openRoom(roomId: String) async {
        // NavigationStack 준비 대기
        try? await Task.sleep(for: .milliseconds(200))
        if let room = state.rooms.first(where: { $0.roomId == roomId }) {
            reduce { $0.selectedRoom = room }
        } else {
            // rooms가 아직 로드되지 않은 경우 pending 저장 → fetchRoomsAndConnect 완료 후 처리
            reduce { $0.pendingDeepLinkRoomId = roomId }
        }
    }

    private func listenForMessages() async {
        for await message in SocketIOManager.shared.messageStream() {
            guard !Task.isCancelled else { break }
            chatRepo.save(message: message)
            reduce { state in
                state.roomLastMessages[message.roomId] = message
                state.rooms = state.rooms.sorted { a, b in
                    let dateA = state.roomLastMessages[a.roomId]?.createdAt ?? a.updatedAt
                    let dateB = state.roomLastMessages[b.roomId]?.createdAt ?? b.updatedAt
                    return dateA > dateB
                }
            }
        }
    }
}
