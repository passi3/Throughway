//
//  UserProfileViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class UserProfileViewModel: BaseViewModel<UserProfileFeature.State, UserProfileFeature.Intent> {

    let user: UserInfoResponseDTO
    private let myUserId: String
    private let chatAPIClient: ChatAPIClient
    var onChatReady: ((ChatRoomDTO) -> Void)?

    init(
        user: UserInfoResponseDTO,
        myUserId: String,
        chatAPIClient: ChatAPIClient = .live
    ) {
        self.user = user
        self.myUserId = myUserId
        self.chatAPIClient = chatAPIClient
        super.init(initialState: .init())
    }

    override func send(_ intent: UserProfileFeature.Intent) {
        switch intent {
        case .chatTapped:
            Task { await createOrGetRoom() }
        }
    }

    private func createOrGetRoom() async {
        reduce { $0.isCreatingRoom = true }
        defer { reduce { $0.isCreatingRoom = false } }
        do {
            let room = try await chatAPIClient.createOrGetRoom(user.userId)
            onChatReady?(room)
        } catch {
            print("[UserProfile] createOrGetRoom failed: \(error.localizedDescription)")
        }
    }
}
