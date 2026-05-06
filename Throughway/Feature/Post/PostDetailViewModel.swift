//
//  PostDetailViewModel.swift
//  Throughway
//
//  Created by passi on 5/5/26.
//

import Foundation

@MainActor
final class PostDetailViewModel: BaseViewModel<PostDetailFeature.State, PostDetailFeature.Intent> {

    let summary: PostDTO
    private let postClient: PostAPIClient
    private let onCommentCreated: () -> Void
    private let onCommentDeleted: () -> Void

    var currentIsLike: Bool {
        state.likeOverride?.isLike ?? state.post?.isLike ?? summary.isLike
    }

    var currentLikeCount: Int {
        state.likeOverride?.likeCount ?? state.post?.likeCount ?? summary.likeCount
    }

    init(
        post: PostDTO,
        postClient: PostAPIClient = .live,
        onCommentCreated: @escaping () -> Void = {},
        onCommentDeleted: @escaping () -> Void = {}
    ) {
        self.summary = post
        self.postClient = postClient
        self.onCommentCreated = onCommentCreated
        self.onCommentDeleted = onCommentDeleted
        super.init(initialState: .init())
    }

    override func send(_ intent: PostDetailFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchDetail() }

        case .likeTapped:
            Task { await toggleLike() }

        case .commentTextChanged(let text):
            reduce { $0.commentText = text }

        case .replyTapped(let commentId, let nick):
            reduce { $0.replyingTo = (commentId, nick) }

        case .cancelReply:
            reduce { $0.replyingTo = nil }

        case .submitComment:
            Task { await submitComment() }

        case .startEditing(let commentId, let content):
            reduce {
                $0.editingCommentId = commentId
                $0.commentText = content
                $0.replyingTo = nil
            }

        case .cancelEditing:
            reduce {
                $0.editingCommentId = nil
                $0.commentText = ""
            }

        case .deleteComment(let commentId):
            Task { await deleteComment(commentId: commentId) }
        }
    }

    private func fetchDetail() async {
        reduce { $0.isLoadingPost = true }
        do {
            let post = try await postClient.fetchDetail(summary.postId)
            reduce {
                $0.post = post
                $0.comments = post.comments
            }
        } catch {
            print("[PostDetail] fetchDetail failed: \(error.localizedDescription)")
        }
        reduce { $0.isLoadingPost = false }
    }

    private func toggleLike() async {
        let currentLike = currentIsLike
        let currentCount = currentLikeCount
        let newIsLike = !currentLike
        let newCount = max(0, currentCount + (newIsLike ? 1 : -1))

        reduce { $0.likeOverride = (newIsLike, newCount) }

        do {
            let response = try await postClient.toggleLike(summary.postId, newIsLike)
            reduce { $0.likeOverride = (response.isLiked, newCount) }
        } catch {
            print("[PostDetail] toggleLike failed: \(error.localizedDescription)")
            reduce { $0.likeOverride = (currentLike, currentCount) }
        }
    }

    private func submitComment() async {
        let text = state.commentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        reduce { $0.isSubmittingComment = true }

        if let editingId = state.editingCommentId {
            do {
                _ = try await postClient.updateComment(summary.postId, editingId, UpdateCommentRequestDTO(content: text))
                reduce {
                    $0.commentText = ""
                    $0.editingCommentId = nil
                }
                await fetchDetail()
            } catch {
                print("[PostDetail] updateComment failed: \(error.localizedDescription)")
            }
        } else {
            let parentId = state.replyingTo?.commentId
            do {
                let dto = CreateCommentRequestDTO(content: text, parentCommentId: parentId)
                _ = try await postClient.createComment(summary.postId, dto)
                reduce {
                    $0.commentText = ""
                    $0.replyingTo = nil
                }
                onCommentCreated()
                await fetchDetail()
            } catch {
                print("[PostDetail] createComment failed: \(error.localizedDescription)")
            }
        }

        reduce { $0.isSubmittingComment = false }
    }

    private func deleteComment(commentId: String) async {
        do {
            try await postClient.deleteComment(summary.postId, commentId)
            onCommentDeleted()
            await fetchDetail()
        } catch {
            print("[PostDetail] deleteComment failed: \(error.localizedDescription)")
        }
    }
}
