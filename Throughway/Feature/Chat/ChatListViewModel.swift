//
//  ChatListViewModel.swift
//  Throughway
//

import Foundation

@MainActor
final class ChatListViewModel: BaseViewModel<ChatListFeature.State, ChatListFeature.Intent> {

    private let chatClient: ChatAPIClient
    private let tokenClient: TokenClient

    init(
        chatClient: ChatAPIClient = .live,
        tokenClient: TokenClient = .live
    ) {
        self.chatClient = chatClient
        self.tokenClient = tokenClient
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
        // accessToken JWT에서 userId 디코딩 또는 UserDefaults 캐싱
        if let cached = UserDefaults.standard.string(forKey: "myUserId"), !cached.isEmpty {
            reduce { $0.myUserId = cached }
        }
    }

    private func fetchRooms() async {
        reduce { $0.isLoading = true }
        defer { reduce { $0.isLoading = false } }
        do {
            let response = try await chatClient.fetchRooms()
            let sorted = response.data.sorted { $0.updatedAt > $1.updatedAt }
            reduce { $0.rooms = sorted }
        } catch {
            print("[ChatList] fetchRooms error:", error)
        }
    }
}
