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
                    .foregroundStyle(Color.gray15)

                postGrid
            }
        }
        .background(Color.gray0)
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
                    .font(.Pretendard.body2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)

                if let intro = viewModel.user.introduction, !intro.isEmpty {
                    Text(intro)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)
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
                    .foregroundStyle(Color.gray30)
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
                        .tint(Color.gray0)
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color.gray0)
                }
            }
            .frame(width: 44, height: 44)
            .background(Color.blackSeafoam)
            .clipShape(Circle())
        }
        .disabled(viewModel.state.isCreatingRoom)
    }

    // MARK: - Post Grid

    @ViewBuilder
    private var postGrid: some View {
        if viewModel.state.isLoadingPosts {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 60)
        } else if viewModel.state.posts.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.gray30)
                Text("게시물이 없습니다")
                    .font(.Pretendard.body3)
                    .foregroundStyle(Color.gray45)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(viewModel.state.posts, id: \.postId) { post in
                    postThumbnail(post)
                }
            }
        }
    }

    private func postThumbnail(_ post: PostDTO) -> some View {
        GeometryReader { geo in
            Group {
                if let first = post.files.first, let url = first.serverImageURL {
                    KFImage(url)
                        .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 200, height: 200)))
                        .requestModifier(AuthImageModifier())
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.gray15)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 20))
                                .foregroundStyle(Color.gray30)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.width)
            .clipped()
            .overlay(alignment: .topTrailing) {
                if post.files.count > 1 {
                    Image(systemName: "square.on.square")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.gray0)
                        .shadow(radius: 2)
                        .padding(6)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}
