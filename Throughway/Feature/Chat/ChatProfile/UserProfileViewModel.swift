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
    private let postAPIClient: PostAPIClient
    var onChatReady: ((ChatRoomDTO) -> Void)?

    init(
        user: UserInfoResponseDTO,
        myUserId: String,
        chatAPIClient: ChatAPIClient = .live,
        postAPIClient: PostAPIClient = .live
    ) {
        self.user = user
        self.myUserId = myUserId
        self.chatAPIClient = chatAPIClient
        self.postAPIClient = postAPIClient
        super.init(initialState: .init())
    }

    override func send(_ intent: UserProfileFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchUserPosts() }
        case .chatTapped:
            Task { await createOrGetRoom() }
        }
    }

    private func fetchUserPosts() async {
        reduce { $0.isLoadingPosts = true }
        defer { reduce { $0.isLoadingPosts = false } }
        do {
            let result = try await postAPIClient.fetchUserPosts(user.userId)
            reduce { $0.posts = result.data }
        } catch {
            print("[UserProfile] fetchUserPosts failed: \(error.localizedDescription)")
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
