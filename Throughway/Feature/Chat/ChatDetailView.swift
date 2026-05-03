//
//  ChatDetailView.swift
//  Throughway
//

import SwiftUI
import Kingfisher

struct ChatDetailView: View {
    @StateObject private var viewModel: ChatDetailViewModel
    private let room: ChatRoomDTO

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
            messageList
            inputBar
        }
        .navigationTitle(opponentName)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray0)
        .task { viewModel.send(.onAppear) }
        .onDisappear { viewModel.send(.onDisappear) }
    }

    // MARK: - Message List

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.state.isLoadingHistory {
                        ProgressView()
                            .padding(.top, 12)
                    }
                    ForEach(viewModel.state.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isOwn: message.sender.userId == viewModel.state.myUserId
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

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("메시지 입력...", text: Binding(
                get: { viewModel.state.inputText },
                set: { viewModel.send(.inputChanged($0)) }
            ), axis: .vertical)
            .lineLimit(1...3)
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
                        viewModel.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.state.isSending
                        ? Color.gray30
                        : Color.blackSeafoam
                    )
            }
            .disabled(
                viewModel.state.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                viewModel.state.isSending
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray0)
        .overlay(alignment: .top) {
            Divider()
        }
    }
}

// MARK: - Message Bubble

private struct MessageBubbleView: View {
    let message: ChatMessageDTO
    let isOwn: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isOwn { Spacer(minLength: 60) }

            if !isOwn {
                profileImage
            }

            VStack(alignment: isOwn ? .trailing : .leading, spacing: 4) {
                if !isOwn {
                    Text(message.sender.nick)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)
                }
                Text(message.content)
                    .font(.Pretendard.body2)
                    .foregroundStyle(isOwn ? .white : Color.gray90)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isOwn ? Color.blackSeafoam : Color.gray15)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(message.createdAt.messageTimeLabel)
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray45)
            }

            if isOwn { EmptyView() } else { Spacer(minLength: 60) }
        }
    }

    private var profileImage: some View {
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
    }
}

// MARK: - Date Formatter

private extension String {
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
