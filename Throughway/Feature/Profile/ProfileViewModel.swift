//
//  ProfileViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class ProfileViewModel: BaseViewModel<ProfileFeature.State, ProfileFeature.Intent> {

    private let userClient: UserAPIClient
    private let postClient: PostAPIClient
    private let activityClient: ActivityAPIClient

    init(
        userClient: UserAPIClient = .live,
        postClient: PostAPIClient = .live,
        activityClient: ActivityAPIClient = .live
    ) {
        self.userClient = userClient
        self.postClient = postClient
        self.activityClient = activityClient
        super.init(initialState: .init())
    }

    override func send(_ intent: ProfileFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchProfile() }
        case .tabChanged(let tab):
            reduce { $0.selectedTab = tab }
        case .profileImageSelected(let data):
            Task { await uploadProfileImage(data) }
        case .nickEditTapped:
            reduce {
                $0.nickDraft = $0.profile?.nick ?? ""
                $0.isEditingNick = true
            }
        case .nickChanged(let text):
            reduce { $0.nickDraft = text; $0.nickError = nil }
        case .nickSaveTapped:
            Task { await updateNick() }
        case .nickEditDismissed:
            reduce { $0.isEditingNick = false; $0.nickError = nil }
        }
    }

    // MARK: - Private

    private func fetchProfile() async {
        reduce { $0.isLoadingProfile = true }
        defer { reduce { $0.isLoadingProfile = false } }
        do {
            let profile = try await userClient.fetchMyProfile()
            reduce { $0.profile = profile }
            async let posts: () = fetchPosts(userId: profile.userId)
            async let reviews: () = fetchReviews(userId: profile.userId)
            _ = await (posts, reviews)
        } catch {
            print("[Profile] fetchProfile failed: \(error.localizedDescription)")
        }
    }

    private func fetchPosts(userId: String) async {
        reduce { $0.isLoadingPosts = true }
        defer { reduce { $0.isLoadingPosts = false } }
        do {
            let result = try await postClient.fetchUserPosts(userId)
            reduce { $0.posts = result.data }
        } catch {
            print("[Profile] fetchPosts failed: \(error.localizedDescription)")
        }
    }

    private func fetchReviews(userId: String) async {
        reduce { $0.isLoadingReviews = true }
        defer { reduce { $0.isLoadingReviews = false } }
        do {
            let result = try await activityClient.fetchUserReviews(userId)
            reduce { $0.reviews = result.data }
        } catch {
            print("[Profile] fetchReviews failed: \(error.localizedDescription)")
        }
    }

    private func uploadProfileImage(_ data: Data) async {
        reduce { $0.isUploadingImage = true }
        defer { reduce { $0.isUploadingImage = false } }
        do {
            let imageResponse = try await userClient.uploadProfileImage(data)
            _ = try await userClient.updateMyProfile(.init(
                nick: nil,
                phoneNum: nil,
                introduction: nil,
                profileImage: imageResponse.profileImage
            ))
            await fetchProfile()
        } catch {
            print("[Profile] uploadProfileImage failed: \(error.localizedDescription)")
        }
    }

    private func updateNick() async {
        let draft = state.nickDraft
        if let error = validateNick(draft) {
            reduce { $0.nickError = error }
            return
        }
        reduce { $0.isUpdatingNick = true }
        defer { reduce { $0.isUpdatingNick = false } }
        do {
            _ = try await userClient.updateMyProfile(.init(nick: draft, phoneNum: nil, introduction: nil, profileImage: nil))
            reduce { $0.isEditingNick = false; $0.nickError = nil }
            await fetchProfile()
        } catch {
            reduce { $0.nickError = "사용할 수 없는 닉네임입니다" }
            print("[Profile] updateNick failed: \(error.localizedDescription)")
        }
    }

    private func validateNick(_ nick: String) -> String? {
        if nick.isEmpty { return "닉네임을 입력해주세요" }
        let invalid = CharacterSet(charactersIn: "-.,?*@+^${}()|[]\\")
        if nick.rangeOfCharacter(from: invalid) != nil {
            return "사용할 수 없는 닉네임입니다"
        }
        return nil
    }
}
