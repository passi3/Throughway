//
//  UserProfileView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher

struct UserProfileView: View {
    let onChatReady: (ChatRoomDTO) -> Void

    @StateObject private var viewModel: UserProfileViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    init(user: UserInfoResponseDTO, myUserId: String, onChatReady: @escaping (ChatRoomDTO) -> Void) {
        self.onChatReady = onChatReady
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(user: user, myUserId: myUserId))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHeader
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)

                Divider()
                    .foregroundStyle(Color.border)

                tabBar
                    .padding(.top, 4)

                tabContent
            }
        }
        .background(Color.bgPrimary)
        .navigationTitle(viewModel.user.nick)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onChatReady = onChatReady
            viewModel.send(.onAppear)
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            profileImage

            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.user.nick)
                    .font(.Pretendard.body3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.textPrimary)

                if let intro = viewModel.user.introduction, !intro.isEmpty {
                    Text(intro)
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            chatButton
        }
    }

    private var profileImage: some View {
        Group {
            if let path = viewModel.user.profileImage, let url = path.serverImageURL {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 56, height: 56)))
                    .requestModifier(AuthImageModifier())
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }

    private var chatButton: some View {
        Button {
            viewModel.send(.chatTapped)
        } label: {
            Group {
                if viewModel.state.isCreatingRoom {
                    ProgressView()
                        .tint(Color.bgPrimary)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.bgPrimary)
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.primary)
            .clipShape(Circle())
        }
        .disabled(viewModel.state.isCreatingRoom)
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(tab: .posts, icon: "square.grid.3x3.fill")
            tabBarItem(tab: .reviews, icon: "star.fill")
        }
    }

    private func tabBarItem(tab: UserProfileFeature.Tab, icon: String) -> some View {
        let isSelected = viewModel.state.selectedTab == tab
        return Button {
            viewModel.send(.tabChanged(tab))
        } label: {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.primary : Color.textTertiary)
                    .frame(height: 40)

                Rectangle()
                    .fill(isSelected ? Color.primary : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }

    // MARK: - Tab Content

    @ViewBuilder
    private var tabContent: some View {
        switch viewModel.state.selectedTab {
        case .posts:
            postGrid
        case .reviews:
            reviewGrid
        }
    }

    // MARK: - Post Grid

    @ViewBuilder
    private var postGrid: some View {
        if viewModel.state.isLoadingPosts {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if viewModel.state.posts.isEmpty {
            emptyView(text: "작성한 게시물이 없습니다", icon: "photo.on.rectangle.angled")
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.state.posts, id: \.postId) { post in
                    gridThumbnail(
                        path: post.files.first,
                        hasMultiple: post.files.count > 1
                    )
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Review Grid

    @ViewBuilder
    private var reviewGrid: some View {
        if viewModel.state.isLoadingReviews {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if viewModel.state.reviews.isEmpty {
            emptyView(text: "작성한 리뷰가 없습니다", icon: "star.slash")
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.state.reviews, id: \.activityId) { activity in
                    gridThumbnail(
                        path: activity.thumbnails.first,
                        hasMultiple: false
                    )
                    .overlay(alignment: .bottomLeading) {
                        Text(activity.title)
                            .font(.Pretendard.caption3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.bgPrimary)
                            .lineLimit(2)
                            .padding(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [.clear, .black.opacity(0.55)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            }
            .padding(.top, 2)
        }
    }

    // MARK: - Shared

    private func gridThumbnail(path: String?, hasMultiple: Bool) -> some View {
        GeometryReader { geo in
            Group {
                if let path {
                    if path.isVideoPath {
                        if let url = path.serverImageURL {
                            LoopingVideoView(url: url)
                                .frame(width: geo.size.width, height: geo.size.width)
                                .clipped()
                        } else {
                            gridPlaceholder(size: geo.size.width)
                        }
                    } else if let url = path.serverImageURL {
                        KFImage(url)
                            .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                            .requestModifier(AuthImageModifier())
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.width)
                            .clipped()
                    } else {
                        gridPlaceholder(size: geo.size.width)
                    }
                } else {
                    gridPlaceholder(size: geo.size.width)
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if hasMultiple {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.bgPrimary)
                        .shadow(radius: 2)
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func gridPlaceholder(size: CGFloat) -> some View {
        Rectangle()
            .fill(Color.bgTertiary)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textTertiary)
            )
    }

    private func emptyView(text: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)
            Text(text)
                .font(.Pretendard.body4)
                .foregroundStyle(Color.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
