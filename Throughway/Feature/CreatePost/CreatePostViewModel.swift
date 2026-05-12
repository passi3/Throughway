//
//  CreatePostViewModel.swift
//  Throughway
//
//  Created by passi on 5/11/26.
//

import Foundation

@MainActor
final class CreatePostViewModel: BaseViewModel<CreatePostFeature.State, CreatePostFeature.Intent> {

    private let postClient: PostAPIClient

    init(
        postClient: PostAPIClient = .live,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.postClient = postClient
        super.init(initialState: .init(latitude: latitude, longitude: longitude))
    }

    init(
        postClient: PostAPIClient = .live,
        post: PostDTO,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.postClient = postClient
        var initial = CreatePostFeature.State(latitude: latitude, longitude: longitude)
        initial.postId = post.postId
        initial.existingFilePaths = post.files
        initial.country = post.country
        initial.category = post.category
        initial.title = post.title
        initial.content = post.content
        super.init(initialState: initial)
    }

    override func send(_ intent: CreatePostFeature.Intent) {
        switch intent {
        case .countryChanged(let value):
            reduce { $0.country = value }
        case .categoryChanged(let value):
            reduce { $0.category = value }
        case .titleChanged(let value):
            reduce { $0.title = value }
        case .contentChanged(let value):
            reduce { $0.content = value }
        case .photosSelected(let data):
            reduce { $0.selectedImageData.append(contentsOf: data) }
        case .removePhoto(let index):
            reduce { $0.selectedImageData.remove(at: index) }
        case .removeExistingPhoto(let index):
            reduce { $0.existingFilePaths.remove(at: index) }
        case .submit:
            Task { await submit() }
        }
    }

    private func submit() async {
        let trimmedTitle = state.title.trimmingCharacters(in: .whitespaces)
        let trimmedContent = state.content.trimmingCharacters(in: .whitespaces)

        guard let country = state.country else {
            reduce { $0.error = "국가를 선택해주세요" }
            return
        }
        guard let category = state.category else {
            reduce { $0.error = "카테고리를 선택해주세요" }
            return
        }
        guard !trimmedTitle.isEmpty else {
            reduce { $0.error = "제목을 입력해주세요" }
            return
        }
        guard !trimmedContent.isEmpty else {
            reduce { $0.error = "내용을 입력해주세요" }
            return
        }

        reduce { $0.error = nil; $0.isSubmitting = true }

        do {
            var newFilePaths: [String] = []
            if !state.selectedImageData.isEmpty {
                let response = try await postClient.uploadFiles(state.selectedImageData)
                newFilePaths = response.files
            }
            let allFiles = state.existingFilePaths + newFilePaths

            if let postId = state.postId {
                let dto = UpdatePostRequestDTO(
                    country: country,
                    category: category,
                    title: trimmedTitle,
                    content: trimmedContent,
                    files: allFiles,
                    activityId: nil,
                    latitude: state.latitude,
                    longitude: state.longitude
                )
                _ = try await postClient.updatePost(postId, dto)
            } else {
                let dto = CreatePostRequestDTO(
                    country: country,
                    category: category,
                    title: trimmedTitle,
                    content: trimmedContent,
                    files: allFiles,
                    activityId: nil,
                    latitude: state.latitude,
                    longitude: state.longitude
                )
                _ = try await postClient.createPost(dto)
            }
            reduce { $0.isSubmitting = false; $0.didFinish = true }
        } catch {
            reduce { $0.isSubmitting = false; $0.error = error.localizedDescription }
        }
    }
}
