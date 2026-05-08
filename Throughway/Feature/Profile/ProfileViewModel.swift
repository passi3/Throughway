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
    private let orderClient: OrderPaymentAPIClient
    private let reviewClient: ReviewAPIClient
    
    init(
        userClient: UserAPIClient = .live,
        orderClient: OrderPaymentAPIClient = .live,
        reviewClient: ReviewAPIClient = .live
    ) {
        self.userClient = userClient
        self.orderClient = orderClient
        self.reviewClient = reviewClient
        super.init(initialState: .init())
    }
    
    override func send(_ intent: ProfileFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchProfile() }
            
        case .searchTextChanged(let text):
            reduce { $0.searchText = text }
            
        case .writeReviewTapped(let order):
            reduce {
                $0.reviewTarget = order
                $0.reviewRating = 5
                $0.reviewContent = ""
            }
            
        case .reviewRatingChanged(let rating):
            reduce { $0.reviewRating = rating }
            
        case .reviewContentChanged(let text):
            reduce { $0.reviewContent = text }
            
        case .submitReview:
            Task { await submitReview() }
            
        case .reviewDismissed:
            reduce { $0.reviewTarget = nil }
            
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
            await fetchOrders()
        } catch {
            print("[Profile] fetchProfile failed: \(error.localizedDescription)")
        }
    }
    
    private func fetchOrders() async {
        reduce { $0.isLoadingOrders = true }
        defer { reduce { $0.isLoadingOrders = false } }
        do {
            let result = try await orderClient.fetchOrders()
            reduce { $0.orders = result.data }
        } catch {
            print("[Profile] fetchOrders failed: \(error.localizedDescription)")
        }
    }
    
    private func submitReview() async {
        guard let order = state.reviewTarget else { return }
        let content = state.reviewContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        reduce { $0.isSubmittingReview = true }
        defer { reduce { $0.isSubmittingReview = false } }
        
        do {
            let dto = CreateReviewRequestDTO(
                rating: state.reviewRating,
                content: content,
                files: [],
                orderCode: order.orderCode
            )
            _ = try await reviewClient.createReview(order.activity.activityId, dto)
            reduce { $0.reviewTarget = nil }
            await fetchOrders()
        } catch {
            print("[Profile] submitReview failed: \(error.localizedDescription)")
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
