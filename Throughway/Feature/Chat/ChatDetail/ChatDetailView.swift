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

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    private let room: ChatRoomDTO
    @State private var showFilePicker = false

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
        .alert(
            "오류",
            isPresented: Binding(
                get: { viewModel.state.fileUploadError != nil },
                set: { if !$0 { viewModel.send(.dismissFileUploadError) } }
            ),
            presenting: viewModel.state.fileUploadError
        ) { _ in
            Button("확인") { viewModel.send(.dismissFileUploadError) }
        } message: { msg in
            Text(msg)
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
                            showTime: info.showTime
                        )
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
            HStack(spacing: 12) {
                Button {
                    showFilePicker = true
                } label: {
                    Image(systemName: "paperclip")
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
                .font(.Pretendard.body2)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 20))

                Button {
                    viewModel.send(.sendTapped)
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            (viewModel.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                             && viewModel.state.pendingFiles.isEmpty)
                            || viewModel.state.isSending
                            ? Color.gray30
                            : Color.blackSeafoam
                        )
                }
                .disabled(
                    (viewModel.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                     && viewModel.state.pendingFiles.isEmpty)
                    || viewModel.state.isSending
                )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color.gray0)
        .overlay(alignment: .top) {
            Divider()
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
