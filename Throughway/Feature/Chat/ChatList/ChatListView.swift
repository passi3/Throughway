//
//  ChatListView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher

struct ChatListView: View {
    @StateObject private var viewModel = ChatListViewModel()
    @State private var isSearchPresented = false
    @State private var pendingRoom: ChatRoomDTO?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.state.isLoading && viewModel.state.rooms.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.state.rooms.isEmpty {
                    emptyView
                } else {
                    roomList
                }
            }
            .navigationTitle("채팅")
            .navigationBarTitleDisplayMode(.large)
            .background(Color.gray0)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(Color.gray90)
                    }
                }
            }
            .navigationDestination(item: Binding(
                get: { viewModel.state.selectedRoom },
                set: { _ in viewModel.send(.clearSelection) }
            )) { room in
                ChatDetailView(room: room, myUserId: viewModel.state.myUserId)
            }
        }
        .onAppear { viewModel.send(.onAppear) }
        .fullScreenCover(isPresented: $isSearchPresented) {
            UserSearchView(myUserId: viewModel.state.myUserId) { room in
                pendingRoom = room
                isSearchPresented = false
            }
        }
        .onChange(of: isSearchPresented) { _, isPresented in
            if !isPresented, let room = pendingRoom {
                viewModel.send(.roomTapped(room))
                pendingRoom = nil
            }
        }
    }

    private var roomList: some View {
        List(viewModel.state.rooms) { room in
            Button {
                viewModel.send(.roomTapped(room))
            } label: {
                ChatRoomRowView(
                    room: room,
                    myUserId: viewModel.state.myUserId,
                    localLastMessage: viewModel.state.roomLastMessages[room.roomId]
                )
            }
            .listRowBackground(Color.gray0)
            .listRowSeparatorTint(Color.gray15)
        }
        .listStyle(.plain)
        .refreshable { viewModel.send(.refresh) }
    }

    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(Color.gray45)
            Text("채팅방이 없습니다")
                .font(.Pretendard.body1)
                .foregroundStyle(Color.gray45)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Row

private struct ChatRoomRowView: View {
    let room: ChatRoomDTO
    let myUserId: String
    let localLastMessage: ChatMessageDTO?

    private var opponent: ChatParticipantDTO? {
        room.participants.first { $0.userId != myUserId }
    }

    private var lastContent: String {
        localLastMessage?.content ?? room.lastChat?.content ?? ""
    }

    var body: some View {
        HStack(spacing: 12) {
            profileImage
            VStack(alignment: .leading, spacing: 4) {
                Text(opponent?.nick ?? "알 수 없음")
                    .font(.Pretendard.body1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)
                Text(lastContent)
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
                    .lineLimit(1)
            }
            Spacer()
            Text(room.updatedAt.chatTimeLabel)
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.gray45)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private var profileImage: some View {
        Group {
            if let path = opponent?.profileImage, let url = path.serverImageURL {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 44, height: 44)))
                    .requestModifier(AuthImageModifier())
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(Color.gray30)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}

// MARK: - Date Formatter

private extension String {
    var chatTimeLabel: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: self) else { return self }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "a h:mm"
            return f.string(from: date)
        } else {
            let f = DateFormatter()
            f.locale = Locale(identifier: "ko_KR")
            f.dateFormat = "M월 d일"
            return f.string(from: date)
        }
    }
}
