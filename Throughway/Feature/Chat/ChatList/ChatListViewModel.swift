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
            Task { await fetchRooms() }

        case .refresh:
            Task { await fetchRooms() }

        case .roomTapped(let room):
            reduce { $0.selectedRoom = room }

        case .clearSelection:
            reduce { $0.selectedRoom = nil }
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

    private func fetchRooms() async {
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
        } catch {
            print("[ChatList] fetchRooms error:", error)
        }
    }
}
