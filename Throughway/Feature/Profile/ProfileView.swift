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
    @State private var cropUIImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader
                        .padding(.horizontal, 16)
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                    Divider()
                        .foregroundStyle(Color.gray15)

                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    orderListSection
                }
            }
            .background(Color.gray0)
            .navigationTitle("PROFILE")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            viewModel.send(.onAppear)
        }
        .onChange(of: selectedPhoto) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    cropUIImage = image.normalized()
                }
                selectedPhoto = nil
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { cropUIImage != nil },
            set: { if !$0 { cropUIImage = nil } }
        )) {
            if let image = cropUIImage {
                CircularCropView(
                    image: image,
                    onConfirm: { data in
                        cropUIImage = nil
                        viewModel.send(.profileImageSelected(data))
                    },
                    onCancel: {
                        cropUIImage = nil
                    }
                )
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.isEditingNick },
            set: { if !$0 { viewModel.send(.nickEditDismissed) } }
        )) {
            nickEditSheet
        }
        .sheet(isPresented: Binding(
            get: { viewModel.state.reviewTarget != nil },
            set: { if !$0 { viewModel.send(.reviewDismissed) } }
        )) {
            reviewSheet
        }
    }
}

// MARK: - Profile Header

private extension ProfileView {

    var profileHeader: some View {
        VStack(spacing: 16) {
            profileImage

            Text(viewModel.state.profile?.nick ?? "불러오는 중...")
                .font(.Pretendard.title1)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray90)

            categoryChips

            statsRow

            HStack(spacing: 12) {
                Button {
                    viewModel.send(.nickEditTapped)
                } label: {
                    Text("프로필 수정")
                        .font(.Pretendard.caption1)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.blackSeafoam)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.lightSeafoam)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                Button("로그아웃", action: onLogout)
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.rosyPunch)
            }
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
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        )
                        .offset(x: -4, y: -4)
                }
        }
        .disabled(viewModel.state.isUploadingImage)
    }

    @ViewBuilder
    var profileImageContent: some View {
        let size: CGFloat = 120
        if viewModel.state.isUploadingImage {
            Circle()
                .fill(Color.gray15)
                .frame(width: size, height: size)
                .overlay(ProgressView().tint(Color.gray45))
        } else if let path = viewModel.state.profile?.profileImage,
                  let url = path.serverImageURL {
            KFImage(url)
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: size * 2, height: size * 2)))
                .requestModifier(AuthImageModifier())
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .foregroundStyle(Color.gray30)
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    var categoryChips: some View {
        let rankings = viewModel.state.categoryRankings
        if !rankings.isEmpty {
            HStack(spacing: 8) {
                ForEach(rankings, id: \.category) { item in
                    Text("\(item.rank)위 \(item.category)")
                        .font(.Pretendard.caption1)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.blackSeafoam)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.lightSeafoam)
                        .clipShape(Capsule())
                }
            }
        }
    }

    var statsRow: some View {
        HStack(spacing: 24) {
            VStack(spacing: 4) {
                Text(viewModel.state.totalSpent.wonFormatted)
                    .font(.Pretendard.body2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)
                Text("총 사용 금액")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray45)
            }

            Rectangle()
                .fill(Color.gray15)
                .frame(width: 1, height: 30)

            VStack(spacing: 4) {
                Text("\(viewModel.state.totalPoints.formatted())P")
                    .font(.Pretendard.body2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)
                Text("누적 적립 포인트")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray45)
            }
        }
    }
}

// MARK: - Search Bar

private extension ProfileView {

    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.gray45)
                .font(.system(size: 14))

            TextField("내 액티비티를 검색해보세요", text: Binding(
                get: { viewModel.state.searchText },
                set: { viewModel.send(.searchTextChanged($0)) }
            ))
            .font(.Pretendard.body3)
            .foregroundStyle(Color.gray90)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.gray15)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Order List

private extension ProfileView {

    var orderListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("내 액티비티")
                    .font(.Pretendard.body1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if viewModel.state.isLoadingOrders {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
            } else if viewModel.state.filteredOrders.isEmpty {
                emptyOrdersView
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.state.filteredOrders, id: \.orderId) { order in
                        orderCard(order)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    var emptyOrdersView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bag")
                .font(.system(size: 40))
                .foregroundStyle(Color.gray30)
            Text("구매한 액티비티가 없습니다")
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray45)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    func orderCard(_ order: OrderDTO) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(order.activity.title)
                    .font(.Pretendard.body2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)
                    .lineLimit(2)

                if let date = order.reservationItemName {
                    HStack(spacing: 4) {
                        Text(date)
                        if let category = order.activity.category as String? {
                            Text("·")
                            Text(category)
                        }
                    }
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
                }

                HStack(spacing: 4) {
                    Text(order.activity.country)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)

                    Text(order.totalPrice.wonFormatted)
                        .font(.Pretendard.body3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.blackSeafoam)
                }

                Spacer(minLength: 0)

                reviewButton(for: order)
            }

            Spacer(minLength: 0)

            orderThumbnail(order.activity.thumbnails.first)
        }
        .padding(16)
        .frame(minHeight: 140)
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray15, lineWidth: 1)
        )
    }

    @ViewBuilder
    func reviewButton(for order: OrderDTO) -> some View {
        if let review = order.review {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.deepSeafoam)
                Text(String(format: "%.1f", Double(review.rating ?? 0)))
                    .font(.Pretendard.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.gray60)
            }
        } else {
            Button {
                viewModel.send(.writeReviewTapped(order))
            } label: {
                Text("리뷰 작성")
                    .font(.Pretendard.caption1)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.blackSeafoam)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.lightSeafoam)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
        }
    }

    func orderThumbnail(_ path: String?) -> some View {
        Group {
            if let path {
                if path.isVideoPath {
                    VideoThumbnailView(path: path, height: 80, cornerRadius: 8)
                        .frame(width: 80)
                } else {
                    MediaThumbnailView(path: path, height: 80, cornerRadius: 8)
                        .frame(width: 80)
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray15)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 20))
                            .foregroundStyle(Color.gray30)
                    )
            }
        }
    }
}

// MARK: - Review Sheet

private extension ProfileView {

    var reviewSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let order = viewModel.state.reviewTarget {
                    Text(order.activity.title)
                        .font(.Pretendard.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                        .padding(.top, 8)
                }

                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            viewModel.send(.reviewRatingChanged(star))
                        } label: {
                            Image(systemName: star <= viewModel.state.reviewRating ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundStyle(star <= viewModel.state.reviewRating ? Color.deepSeafoam : Color.gray30)
                        }
                    }
                }

                TextEditor(text: Binding(
                    get: { viewModel.state.reviewContent },
                    set: { viewModel.send(.reviewContentChanged($0)) }
                ))
                .font(.Pretendard.body3)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, 20)

                Spacer()
            }
            .navigationTitle("리뷰 작성")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        viewModel.send(.reviewDismissed)
                    }
                    .foregroundStyle(Color.gray60)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("등록") {
                        viewModel.send(.submitReview)
                    }
                    .font(.Pretendard.body3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blackSeafoam)
                    .disabled(
                        viewModel.state.isSubmittingReview ||
                        viewModel.state.reviewContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    )
                }
            }
            .overlay {
                if viewModel.state.isSubmittingReview {
                    ProgressView()
                }
            }
        }
        .presentationDetents([.medium, .large])
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
