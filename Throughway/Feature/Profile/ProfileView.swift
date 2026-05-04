//
//  ProfileView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher
import PhotosUI

struct ProfileView: View {
    let onLogout: () -> Void
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)

                    Divider()
                        .foregroundStyle(Color.gray15)

                    tabBar
                        .padding(.top, 4)

                    tabContent
                }
            }
            .background(Color.gray0)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            viewModel.send(.onAppear)
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    let jpeg: Data
                    if let image = UIImage(data: data),
                       let compressed = image.jpegData(compressionQuality: 0.8) {
                        jpeg = compressed
                    } else {
                        jpeg = data
                    }
                    viewModel.send(.profileImageSelected(jpeg))
                }
                selectedPhoto = nil
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.isEditingNick },
            set: { if !$0 { viewModel.send(.nickEditDismissed) } }
        )) {
            nickEditSheet
        }
    }
}

// MARK: - Profile Header

private extension ProfileView {

    var profileHeader: some View {
        HStack(spacing: 16) {
            profileImage

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(viewModel.state.profile?.nick ?? "불러오는 중...")
                        .font(.Pretendard.body2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.gray90)

                    Button {
                        viewModel.send(.nickEditTapped)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.gray45)
                    }
                }

                if let intro = viewModel.state.profile?.introduction, !intro.isEmpty {
                    Text(intro)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)
                        .lineLimit(2)
                }
            }

            Spacer()

            Button("로그아웃", action: onLogout)
                .font(.Pretendard.body3)
                .foregroundStyle(Color.rosyPunch)
        }
    }

    var profileImage: some View {
        PhotosPicker(
            selection: $selectedPhoto,
            matching: .images
        ) {
            profileImageContent
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.blackSeafoam)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.white)
                        )
                }
        }
        .disabled(viewModel.state.isUploadingImage)
    }

    @ViewBuilder
    var profileImageContent: some View {
        if viewModel.state.isUploadingImage {
            Circle()
                .fill(Color.gray15)
                .frame(width: 56, height: 56)
                .overlay(ProgressView().tint(Color.gray45))
        } else if let path = viewModel.state.profile?.profileImage,
                  let url = path.serverImageURL {
            KFImage(url)
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 56, height: 56)))
                .requestModifier(AuthImageModifier())
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(Color.gray30)
                .frame(width: 56, height: 56)
                .clipShape(Circle())
        }
    }
}

// MARK: - Tab Bar

private extension ProfileView {

    var tabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(tab: .posts, icon: "square.grid.3x3.fill")
            tabBarItem(tab: .reviews, icon: "star.fill")
        }
    }

    func tabBarItem(tab: ProfileFeature.Tab, icon: String) -> some View {
        let isSelected = viewModel.state.selectedTab == tab
        return Button {
            viewModel.send(.tabChanged(tab))
        } label: {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? Color.blackSeafoam : Color.gray30)
                    .frame(height: 40)

                Rectangle()
                    .fill(isSelected ? Color.blackSeafoam : Color.clear)
                    .frame(height: 2)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(.plain)
    }
}

// MARK: - Tab Content

private extension ProfileView {

    @ViewBuilder
    var tabContent: some View {
        switch viewModel.state.selectedTab {
        case .posts:
            postGrid
        case .reviews:
            reviewGrid
        }
    }

    @ViewBuilder
    var postGrid: some View {
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
                        imageURL: post.files.first?.serverImageURL,
                        hasMultiple: post.files.count > 1
                    )
                }
            }
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    var reviewGrid: some View {
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
                        imageURL: activity.thumbnails.first?.serverImageURL,
                        hasMultiple: false
                    )
                    .overlay(alignment: .bottomLeading) {
                        Text(activity.title)
                            .font(.Pretendard.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gray0)
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

    func gridThumbnail(imageURL: URL?, hasMultiple: Bool) -> some View {
        GeometryReader { geo in
            Group {
                if let url = imageURL {
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
                if hasMultiple {
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

    func emptyView(text: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.gray30)
            Text(text)
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray45)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}

// MARK: - Nick Edit Sheet

private extension ProfileView {

    var nickEditSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("닉네임")
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)

                    TextField("닉네임을 입력해주세요", text: Binding(
                        get: { viewModel.state.nickDraft },
                        set: { viewModel.send(.nickChanged($0)) }
                    ))
                    .font(.Pretendard.body2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.gray15)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let error = viewModel.state.nickError {
                        Text(error)
                            .font(.Pretendard.caption2)
                            .foregroundStyle(Color.rosyPunch)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                Spacer()
            }
            .navigationTitle("닉네임 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        viewModel.send(.nickEditDismissed)
                    }
                    .foregroundStyle(Color.gray60)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("저장") {
                        viewModel.send(.nickSaveTapped)
                    }
                    .font(.Pretendard.body3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blackSeafoam)
                    .disabled(viewModel.state.isUpdatingNick || viewModel.state.nickDraft.isEmpty)
                }
            }
            .overlay {
                if viewModel.state.isUpdatingNick {
                    ProgressView()
                }
            }
        }
        .presentationDetents([.medium])
    }
}
