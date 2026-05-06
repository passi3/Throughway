//
//  ChatDetailView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher
import UniformTypeIdentifiers
import UIKit
import PhotosUI

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    private let room: ChatRoomDTO
    @State private var showFilePicker = false
    @State private var showAttachmentMenu = false
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @State private var selectedImageIndex: Int? = nil
    @FocusState private var isTextFieldFocused: Bool

    init(room: ChatRoomDTO, myUserId: String) {
        self.room = room
        _viewModel = StateObject(wrappedValue: ChatDetailViewModel(room: room, myUserId: myUserId))
    }

    private var opponentName: String {
        room.participants
            .first { $0.userId != viewModel.state.myUserId }?
            .nick ?? "채팅"
    }

    var body: some View {
        VStack(spacing: 0) {
            if let profile = viewModel.state.updatedOpponentProfile {
                UpdatedProfileBanner(profile: profile) {
                    viewModel.send(.dismissProfileUpdate)
                }
            }
            messageList
            inputBar
        }
        .navigationTitle(opponentName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray0)
        .task { viewModel.send(.onAppear) }
        .onDisappear { viewModel.send(.onDisappear) }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.jpeg, .png, .gif, .pdf],
            allowsMultipleSelection: true
        ) { result in
            guard case .success(let urls) = result else { return }
            let picked = urls.compactMap { url -> PendingFilePickResult? in
                guard url.startAccessingSecurityScopedResource() else { return nil }
                defer { url.stopAccessingSecurityScopedResource() }
                guard let data = try? Data(contentsOf: url) else { return nil }
                return PendingFilePickResult(data: data, fileName: url.lastPathComponent, ext: url.pathExtension)
            }
            viewModel.send(.filesPicked(picked))
        }
        .fullScreenCover(isPresented: Binding(
            get: { selectedImageIndex != nil },
            set: { if !$0 { selectedImageIndex = nil } }
        )) {
            if let index = selectedImageIndex {
                ImageViewerView(items: allImageItems, initialIndex: index) {
                    selectedImageIndex = nil
                }
            }
        }
        .alert("메시지를 입력해주세요", isPresented: Binding(
            get: { viewModel.state.showEmptyTextAlert },
            set: { if !$0 { viewModel.send(.dismissEmptyTextAlert) } }
        )) {
            Button("확인", role: .cancel) { viewModel.send(.dismissEmptyTextAlert) }
        } message: {
            Text("파일을 전송할 때는 메시지를 함께 입력해야 합니다.")
        }
        .alert("전송 실패", isPresented: Binding(
            get: { viewModel.state.showSendFailedAlert },
            set: { if !$0 { viewModel.send(.dismissSendFailedAlert) } }
        )) {
            Button("확인", role: .cancel) { viewModel.send(.dismissSendFailedAlert) }
        } message: {
            Text("전송에 실패했습니다.")
        }
    }

    private var allImageItems: [ImageViewerItem] {
        viewModel.state.messages.flatMap { msg in
            msg.files
                .filter { !$0.lowercased().hasSuffix(".pdf") }
                .compactMap { path -> ImageViewerItem? in
                    guard let url = path.serverImageURL else { return nil }
                    return ImageViewerItem(url: url, senderNick: msg.sender.nick, createdAt: msg.createdAt)
                }
        }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 2) {
                    if viewModel.state.isLoadingHistory {
                        ProgressView()
                            .padding(.top, 12)
                    }
                    ForEach(displayInfos, id: \.message.id) { info in
                        if info.showDateDivider {
                            DateDividerView(label: info.message.createdAt.dayLabel)
                        }
                        MessageBubbleView(
                            message: info.message,
                            isOwn: info.isOwn,
                            showProfile: info.showProfile,
                            showTime: info.showTime,
                            onImageTapped: { url in
                                if let index = allImageItems.firstIndex(where: { $0.url == url }) {
                                    selectedImageIndex = index
                                }
                            }
                        )
                    }
                    ForEach(viewModel.state.pendingMessages) { pending in
                        PendingMessageBubbleView(pending: pending) { id in
                            viewModel.send(.retryPending(id))
                        } onDelete: { id in
                            viewModel.send(.deletePending(id))
                        }
                    }
                    Color.clear
                        .frame(height: 1)
                        .id("bottom")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.state.messages.count) {
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: viewModel.state.pendingMessages.count) {
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    private var displayInfos: [MessageDisplayInfo] {
        let messages = viewModel.state.messages
        let myId = viewModel.state.myUserId
        return messages.enumerated().map { i, msg in
            let prev = i > 0 ? messages[i - 1] : nil
            let next = i < messages.count - 1 ? messages[i + 1] : nil
            let isOwn = msg.sender.userId == myId
            let showDateDivider: Bool = prev == nil || prev!.createdAt.dayKey != msg.createdAt.dayKey
            let showProfile: Bool = !isOwn && (
                prev == nil ||
                prev!.sender.userId != msg.sender.userId &&
                prev!.createdAt.minuteKey != msg.createdAt.minuteKey
            )
            let showTime: Bool = next == nil || next!.createdAt.minuteKey != msg.createdAt.minuteKey
            return MessageDisplayInfo(
                message: msg,
                isOwn: isOwn,
                showDateDivider: showDateDivider,
                showProfile: showProfile,
                showTime: showTime
            )
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        VStack(spacing: 0) {
            if !viewModel.state.pendingFiles.isEmpty {
                filePreviewStrip
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
            }
            if showAttachmentMenu {
                HStack(spacing: 24) {
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: max(0, 5 - viewModel.state.pendingFiles.count),
                        matching: .images
                    ) {
                        attachmentMenuButton(icon: "photo.fill", label: "사진 첨부")
                    }
                    .onChange(of: selectedPhotoItems) { _, items in
                        Task {
                            var picked: [PendingFilePickResult] = []
                            for item in items {
                                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                                let ext = item.supportedContentTypes.first?.preferredFilenameExtension ?? "jpg"
                                let name = "\(UUID().uuidString).\(ext)"
                                picked.append(PendingFilePickResult(data: data, fileName: name, ext: ext))
                            }
                            selectedPhotoItems = []
                            if !picked.isEmpty {
                                viewModel.send(.filesPicked(picked))
                                isTextFieldFocused = true
                            }
                            withAnimation(.spring(response: 0.3)) { showAttachmentMenu = false }
                        }
                    }

                    Button {
                        showFilePicker = true
                        withAnimation(.spring(response: 0.3)) { showAttachmentMenu = false }
                        isTextFieldFocused = true
                    } label: {
                        attachmentMenuButton(icon: "doc.fill", label: "파일 첨부")
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3)) { showAttachmentMenu.toggle() }
                } label: {
                    Image(systemName: showAttachmentMenu ? "xmark" : "plus")
                        .font(.system(size: 20))
                        .foregroundStyle(Color.gray60)
                }
                .disabled(viewModel.state.pendingFiles.count >= 5)

                TextField("메시지 입력...", text: Binding(
                    get: { viewModel.state.inputText },
                    set: { viewModel.send(.inputChanged($0)) }
                ), axis: .vertical)
                .lineLimit(1...3)
                .submitLabel(.send)
                .onSubmit { viewModel.send(.sendTapped) }
                .focused($isTextFieldFocused)
                .font(.Pretendard.body2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                let hasText = !viewModel.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                Button {
                    viewModel.send(.sendTapped)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(hasText ? Color.blackSeafoam : Color.gray30)
                }
                .disabled(!hasText)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.gray0)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func attachmentMenuButton(icon: String, label: String) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color.gray15)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.gray60)
                }
            Text(label)
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.gray60)
        }
    }

    private var filePreviewStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.state.pendingFiles) { file in
                    PendingFileChip(file: file) {
                        viewModel.send(.removePendingFile(file.id))
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }
}

// MARK: - Updated Profile Banner

private struct UpdatedProfileBanner: View {
    let profile: ChatParticipantDTO
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            profileImage

            VStack(alignment: .leading, spacing: 2) {
                Text("업데이트 프로필")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray45)
                Text(profile.nick)
                    .font(.Pretendard.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)
            }

            Spacer()

            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.gray45)
                    .padding(6)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.gray15)
        .overlay(alignment: .bottom) { Divider() }
    }

    private var profileImage: some View {
        Group {
            if let path = profile.profileImage, let url = path.serverImageURL {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 40, height: 40)))
                    .requestModifier(AuthImageModifier())
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(Color.gray30)
            }
        }
        .frame(width: 40, height: 40)
        .clipShape(Circle())
    }
}

// MARK: - Display Info

private struct MessageDisplayInfo {
    let message: ChatMessageDTO
    let isOwn: Bool
    let showDateDivider: Bool
    let showProfile: Bool
    let showTime: Bool
}

// MARK: - Date Divider

private struct DateDividerView: View {
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray15)
            Text(label)
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.gray45)
                .lineLimit(1)
                .fixedSize()
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray15)
        }
        .padding(.vertical, 10)
    }
}

// MARK: - Message Bubble

private struct MessageBubbleView: View {
    let message: ChatMessageDTO
    let isOwn: Bool
    let showProfile: Bool
    let showTime: Bool
    var onImageTapped: ((URL) -> Void)? = nil

    @State private var isExpanded = false

    private static let truncationLimit = 300

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isOwn {
                Spacer(minLength: 60)
                timeLabel
                bubble
            } else {
                profileImageView
                VStack(alignment: .leading, spacing: 2) {
                    if showProfile {
                        Text(message.sender.nick)
                            .font(.Pretendard.caption1)
                            .foregroundStyle(Color.gray60)
                            .padding(.bottom, 2)
                    }
                    HStack(alignment: .bottom, spacing: 4) {
                        bubble
                        timeLabel
                    }
                }
                Spacer(minLength: 60)
            }
        }
        .padding(.top, showProfile ? 8 : 0)
    }

    private var isLong: Bool { message.content.count > Self.truncationLimit }

    private var displayContent: String {
        guard isLong, !isExpanded else { return message.content }
        return String(message.content.prefix(Self.truncationLimit)) + "..."
    }

    private var bubble: some View {
        VStack(alignment: isOwn ? .trailing : .leading, spacing: 6) {
            if !message.files.isEmpty {
                filesGrid
            }

            if !message.content.isEmpty {
                Text(displayContent)
                    .font(.Pretendard.body2)
                    .foregroundStyle(isOwn ? .white : Color.gray90)

                if isLong {
                    Button {
                        isExpanded.toggle()
                    } label: {
                        Text(isExpanded ? "접기" : "더보기")
                            .font(.Pretendard.caption1)
                            .fontWeight(.semibold)
                            .foregroundStyle(isOwn ? Color.white.opacity(0.75) : Color.blackSeafoam)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isOwn ? Color.blackSeafoam : Color.gray15)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var filesGrid: some View {
        let imageFiles = message.files.filter { !$0.lowercased().hasSuffix(".pdf") }
        let pdfFiles   = message.files.filter {  $0.lowercased().hasSuffix(".pdf") }
        let columns    = [GridItem(.flexible()), GridItem(.flexible())]

        return VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
            if !imageFiles.isEmpty {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(imageFiles, id: \.self) { path in
                        if let url = path.serverImageURL {
                            KFImage(url)
                                .requestModifier(AuthImageModifier())
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .onTapGesture { onImageTapped?(url) }
                        }
                    }
                }
            }

            ForEach(pdfFiles, id: \.self) { path in
                HStack(spacing: 6) {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(isOwn ? .white : Color.gray60)
                    Text((path as NSString).lastPathComponent)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(isOwn ? .white : Color.gray90)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isOwn ? Color.white.opacity(0.15) : Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    private var timeLabel: some View {
        Group {
            if showTime {
                Text(message.createdAt.messageTimeLabel)
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray45)
            } else {
                Color.clear.frame(width: 0, height: 0)
            }
        }
    }

    private var profileImageView: some View {
        Group {
            if showProfile {
                Group {
                    if let path = message.sender.profileImage, let url = path.serverImageURL {
                        KFImage(url)
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 32, height: 32)))
                            .requestModifier(AuthImageModifier())
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundStyle(Color.gray30)
                    }
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
            } else {
                Color.clear.frame(width: 32, height: 1)
            }
        }
    }
}

// MARK: - Pending File Chip

private struct PendingFileChip: View {
    let file: PendingFile
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if file.mimeType.hasPrefix("image/"), let uiImage = UIImage(data: file.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.gray60)
                    Text(file.fileName)
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray60)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 64, height: 64)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.gray90)
                    .background(Color.gray0, in: Circle())
            }
            .offset(x: 6, y: -6)
        }
    }
}

// MARK: - Pending Message Bubble

private struct PendingMessageBubbleView: View {
    let pending: PendingMessage
    let onRetry: (UUID) -> Void
    let onDelete: (UUID) -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            Spacer(minLength: 60)

            if pending.isFailed {
                HStack(spacing: 12) {
                    Button { onRetry(pending.id) } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.gray60)
                    }
                    Button { onDelete(pending.id) } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.8))
                    }
                }
            } else {
                ProgressView()
                    .scaleEffect(0.7)
            }

            VStack(alignment: .trailing, spacing: 6) {
                if !pending.files.isEmpty {
                    pendingFilesPreview
                }
                if !pending.content.isEmpty {
                    Text(pending.content)
                        .font(.Pretendard.body2)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(pending.isFailed ? Color.gray45 : Color.blackSeafoam)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(pending.isFailed ? 0.6 : 1)
        }
        .padding(.top, 8)
    }

    private var pendingFilesPreview: some View {
        let imageFiles = pending.files.filter { $0.mimeType.hasPrefix("image/") }
        let otherFiles = pending.files.filter { !$0.mimeType.hasPrefix("image/") }
        let columns = [GridItem(.flexible()), GridItem(.flexible())]

        return VStack(alignment: .trailing, spacing: 4) {
            if !imageFiles.isEmpty {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(imageFiles) { file in
                        if let uiImage = UIImage(data: file.data) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }
            ForEach(otherFiles) { file in
                HStack(spacing: 6) {
                    Image(systemName: "doc.fill")
                        .foregroundStyle(.white)
                    Text(file.fileName)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

// MARK: - Image Viewer

struct ImageViewerItem {
    let url: URL
    let senderNick: String
    let createdAt: String
}

private struct ImageViewerView: View {
    let items: [ImageViewerItem]
    let initialIndex: Int
    let onDismiss: () -> Void

    @State private var currentIndex: Int

    init(items: [ImageViewerItem], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.items = items
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(items.indices, id: \.self) { i in
                    KFImage(items[i].url)
                        .requestModifier(AuthImageModifier())
                        .resizable()
                        .scaledToFit()
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(alignment: .top) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(Color.white.opacity(0.2), in: Circle())
                }

                Spacer()

                if !items.isEmpty {
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(items[currentIndex].senderNick)
                            .font(.Pretendard.caption1)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        Text(items[currentIndex].createdAt.dayLabel)
                            .font(.Pretendard.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
    }
}

// MARK: - Date Helpers

private extension String {
    /// "yyyy-MM-dd" — 날짜 변경 감지 키
    var dayKey: String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: self) else { return self }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// "2026년 5월 3일 토요일" — 날짜 구분선 표시용
    var dayLabel: String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: self) else { return self }
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월 d일 EEEE"
        return f.string(from: date)
    }

    /// "yyyy-MM-dd HH:mm" — 같은 분 그루핑 키
    var minuteKey: String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = fmt.date(from: self) else { return self }
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }

    var messageTimeLabel: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: self) else { return "" }

        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")

        if Calendar.current.isDateInToday(date) {
            f.dateFormat = "a h:mm"
        } else {
            f.dateFormat = "M/d a h:mm"
        }
        return f.string(from: date)
    }
}
