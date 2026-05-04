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

    init(user: UserInfoResponseDTO, myUserId: String, onChatReady: @escaping (ChatRoomDTO) -> Void) {
        self.onChatReady = onChatReady
        _viewModel = StateObject(wrappedValue: UserProfileViewModel(user: user, myUserId: myUserId))
    }

    var body: some View {
        VStack(spacing: 0) {
            profileSection
            Spacer()
            chatButton
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
        }
        .background(Color.gray0)
        .navigationTitle(viewModel.user.nick)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.onChatReady = onChatReady
        }
    }

    // MARK: - Profile Section

    private var profileSection: some View {
        VStack(spacing: 16) {
            profileImage
                .padding(.top, 40)

            VStack(spacing: 6) {
                Text(viewModel.user.nick)
                    .font(.Pretendard.title1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)

                if let intro = viewModel.user.introduction, !intro.isEmpty {
                    Text(intro)
                        .font(.Pretendard.body2)
                        .foregroundStyle(Color.gray60)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var profileImage: some View {
        Group {
            if let path = viewModel.user.profileImage, let url = path.serverImageURL {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 80, height: 80)))
                    .requestModifier(AuthImageModifier())
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(Color.gray30)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
    }

    // MARK: - Chat Button

    private var chatButton: some View {
        Button {
            viewModel.send(.chatTapped)
        } label: {
            Group {
                if viewModel.state.isCreatingRoom {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("채팅하기")
                        .font(.Pretendard.body1)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blackSeafoam)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.state.isCreatingRoom)
    }
}
