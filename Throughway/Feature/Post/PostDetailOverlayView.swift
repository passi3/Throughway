//
//  PostDetailOverlayView.swift
//  Throughway
//
//  Created by passi on 5/5/26.
//

import SwiftUI
import Kingfisher

struct PostDetailOverlayView: View {
    @StateObject private var viewModel: PostDetailViewModel
    @FocusState private var isCommentFocused: Bool
    let onDismiss: () -> Void

    init(
        post: PostDTO,
        onDismiss: @escaping () -> Void,
        onCommentCreated: @escaping () -> Void = {},
        onCommentDeleted: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(
            wrappedValue: PostDetailViewModel(
                post: post,
                onCommentCreated: onCommentCreated,
                onCommentDeleted: onCommentDeleted
            )
        )
        self.onDismiss = onDismiss
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture {
                    isCommentFocused = false
                    onDismiss()
                }

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        creatorHeader
                        imageCarousel
                        activityLinkSection
                        actionBar
                        Divider()
                            .background(Color.gray15)
                            .padding(.horizontal, 16)
                        commentsSection
                    }
                }

                Divider()
                    .background(Color.gray15)

                commentInputBar
            }
            .background(Color.gray0)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .padding(.horizontal, 16)
            .padding(.vertical, 52)
        }
        .task {
            viewModel.send(.onAppear)
        }
    }
}

// MARK: - Sections

private extension PostDetailOverlayView {

    var post: PostDTO { viewModel.state.post ?? viewModel.summary }
    var currentUserId: String { AppSession.userId }

    var creatorHeader: some View {
        HStack(spacing: 10) {
            KFImage(post.creator.profileImage.flatMap { $0.serverImageURL })
                .requestModifier(AuthImageModifier())
                .placeholder {
                    Circle()
                        .fill(Color.gray15)
                        .overlay(Image(systemName: "person.fill").foregroundStyle(Color.gray45))
                }
                .resizable()
                .scaledToFill()
                .frame(width: 36, height: 36)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(post.creator.nick)
                    .font(.Pretendard.body3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)
                if let country = post.country {
                    Text(country)
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                }
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.gray60)
                    .padding(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    var imageCarousel: some View {
        let files = post.files
        if !files.isEmpty {
            TabView {
                ForEach(files.indices, id: \.self) { index in
                    KFImage(files[index].serverImageURL)
                        .requestModifier(AuthImageModifier())
                        .placeholder {
                            Rectangle()
                                .fill(Color.gray15)
                                .overlay(Image(systemName: "photo").foregroundStyle(Color.gray30))
                        }
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: files.count > 1 ? .automatic : .never))
            .frame(height: 280)
        }
    }

    @ViewBuilder
    var activityLinkSection: some View {
        if post.activityId != nil {
            HStack(spacing: 8) {
                Image(systemName: "tag.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.blackSeafoam)

                Text("관련 액티비티 보기")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.blackSeafoam)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.gray45)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.blackSeafoam.opacity(0.06))
        }
    }

    var actionBar: some View {
        HStack(spacing: 0) {
            actionButton(
                icon: viewModel.currentIsLike ? "heart.fill" : "heart",
                label: "\(viewModel.currentLikeCount)",
                iconColor: viewModel.currentIsLike ? Color.rosyPunch : Color.gray60
            ) {
                viewModel.send(.likeTapped)
            }

            Divider()
                .frame(height: 32)
                .background(Color.gray15)

            actionButton(icon: "bookmark", label: "저장", iconColor: Color.gray60) {}

            Divider()
                .frame(height: 32)
                .background(Color.gray15)

            actionButton(icon: "square.and.arrow.up", label: "공유", iconColor: Color.gray60) {}
        }
        .padding(.vertical, 12)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.gray15, lineWidth: 0)
        )
    }

    func actionButton(icon: String, label: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(iconColor)
                Text(label)
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray60)
            }
            .frame(maxWidth: .infinity)
        }
    }

    var commentsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("댓글")
                .font(.Pretendard.body3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 12)

            if viewModel.state.isLoadingPost && viewModel.state.comments.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else if viewModel.state.comments.isEmpty {
                Text("첫 댓글을 남겨보세요")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.state.comments, id: \.commentId) { comment in
                    commentGroup(comment)
                }
            }
        }
        .padding(.bottom, 12)
    }

    @ViewBuilder
    func commentGroup(_ comment: CommentDTO) -> some View {
        let hasReplies = !comment.replies.isEmpty

        VStack(alignment: .leading, spacing: 0) {
            // 최상위 댓글
            HStack(alignment: .top, spacing: 10) {
                VStack(spacing: 0) {
                    commentAvatar(url: comment.creator.profileImage, size: 32)
                    if hasReplies {
                        Rectangle()
                            .fill(Color.gray15)
                            .frame(width: 1.5)
                            .frame(maxHeight: .infinity)
                            .padding(.top, 4)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(comment.creator.nick)
                            .font(.Pretendard.caption1)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gray90)
                        Text(relativeTime(from: comment.createdAt))
                            .font(.Pretendard.caption2)
                            .foregroundStyle(Color.gray45)
                    }
                    Text(comment.content)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray75)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        viewModel.send(.replyTapped(commentId: comment.commentId, nick: comment.creator.nick))
                        isCommentFocused = true
                    } label: {
                        Text("답글")
                            .font(.Pretendard.caption2)
                            .foregroundStyle(Color.gray45)
                    }
                    .padding(.top, 2)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .modifier(CommentContextMenuModifier(
                isOwner: comment.creator.userId == currentUserId,
                onEdit: {
                    viewModel.send(.startEditing(commentId: comment.commentId, content: comment.content))
                    isCommentFocused = true
                },
                onDelete: {
                    viewModel.send(.deleteComment(commentId: comment.commentId))
                }
            ))

            // 대댓글 (indent)
            replyRows(comment.replies, parentCommentId: comment.commentId)
        }
    }

    @ViewBuilder
    func replyRows(_ replies: [ReplyDTO], parentCommentId: String) -> some View {
        let lastId = replies.last?.commentId
        ForEach(replies, id: \.commentId) { reply in
            replyRow(reply, isLast: reply.commentId == lastId, parentCommentId: parentCommentId)
        }
    }

    func replyRow(_ reply: ReplyDTO, isLast: Bool, parentCommentId: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.gray15)
                    .frame(width: 1.5)
                    .frame(height: isLast ? 16 : nil)
                    .frame(maxHeight: isLast ? nil : .infinity)
                if isLast { Spacer() }
            }
            .frame(width: 32)

            commentAvatar(url: reply.creator.profileImage, size: 24)
                .padding(.leading, 8)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(reply.creator.nick)
                        .font(.Pretendard.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                    Text(relativeTime(from: reply.createdAt))
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                }
                Text(reply.content)
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray75)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    viewModel.send(.replyTapped(commentId: parentCommentId, nick: reply.creator.nick))
                    isCommentFocused = true
                } label: {
                    Text("답글")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                }
                .padding(.top, 2)
            }

            Spacer()
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .padding(.vertical, 6)
        .modifier(CommentContextMenuModifier(
            isOwner: reply.creator.userId == currentUserId,
            onEdit: {
                viewModel.send(.startEditing(commentId: reply.commentId, content: reply.content))
                isCommentFocused = true
            },
            onDelete: {
                viewModel.send(.deleteComment(commentId: reply.commentId))
            }
        ))
    }

    func commentAvatar(url: String?, size: CGFloat) -> some View {
        KFImage(url.flatMap { $0.serverImageURL })
            .requestModifier(AuthImageModifier())
            .placeholder {
                Circle()
                    .fill(Color.gray15)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.4))
                            .foregroundStyle(Color.gray45)
                    )
            }
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    var commentInputBar: some View {
        VStack(spacing: 0) {
            if viewModel.state.editingCommentId != nil {
                HStack {
                    Text("댓글 수정 중")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.blackSeafoam)

                    Spacer()

                    Button {
                        viewModel.send(.cancelEditing)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray45)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color.blackSeafoam.opacity(0.06))
            } else if let replyTarget = viewModel.state.replyingTo {
                HStack {
                    Text("@\(replyTarget.nick)에 답글")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.blackSeafoam)

                    Spacer()

                    Button {
                        viewModel.send(.cancelReply)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray45)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .background(Color.blackSeafoam.opacity(0.06))
            }

            HStack(spacing: 10) {
                TextField("댓글 남기기...", text: Binding(
                    get: { viewModel.state.commentText },
                    set: { viewModel.send(.commentTextChanged($0)) }
                ))
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray90)
                .focused($isCommentFocused)
                .submitLabel(.send)
                .onSubmit {
                    viewModel.send(.submitComment)
                }

                Button {
                    viewModel.send(.submitComment)
                } label: {
                    if viewModel.state.isSubmittingComment {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(viewModel.state.commentText.isEmpty ? Color.gray30 : Color.blackSeafoam)
                    }
                }
                .disabled(viewModel.state.commentText.isEmpty || viewModel.state.isSubmittingComment)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    func relativeTime(from dateString: String) -> String {
        guard let date = AppFormatter.iso8601.date(from: dateString) else { return "" }
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 60    { return "방금 전" }
        if elapsed < 3600  { return "\(Int(elapsed / 60))분 전" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))시간 전" }
        return "\(Int(elapsed / 86400))일 전"
    }
}

// MARK: - Context Menu Modifier

private struct CommentContextMenuModifier: ViewModifier {
    let isOwner: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        if isOwner {
            content.contextMenu {
                Button(action: onEdit) {
                    Label("수정", systemImage: "pencil")
                }
                Button(role: .destructive, action: onDelete) {
                    Label("삭제", systemImage: "trash")
                }
            }
        } else {
            content
        }
    }
}
