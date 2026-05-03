//
//  ProfileView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {
    let onLogout: () -> Void
    @StateObject private var viewModel = ProfileViewModel()
    @State private var selectedFilter: Int = 0

    private let filters = ["전체", "스키·보드", "워터스포츠", "클라이밍", "사이클"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    profileHeader

                    statsSection
                        .padding(.top, 16)

                    actionButtons
                        .padding(.top, 16)
                        .padding(.horizontal, 16)

                    filterChips
                        .padding(.top, 20)

                    contentGrid
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
            .background(Color.gray0)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Profile")
                        .font(.Pretendard.body2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("로그아웃", action: onLogout)
                        .font(.Pretendard.body3)
                        .foregroundStyle(Color.rosyPunch)
                }
            }
        }
        .task {
            viewModel.send(.onAppear)
        }
    }
}

// MARK: - Sections

private extension ProfileView {

    var profileHeader: some View {
        VStack(spacing: 12) {
            Circle()
                .fill(Color.gray15)
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray45)
                )
                .overlay(alignment: .bottomTrailing) {
                    Circle()
                        .fill(Color.blackSeafoam)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 10))
                                .foregroundStyle(.white)
                        )
                }

            VStack(spacing: 4) {
                Text("이름없음")
                    .font(.Pretendard.body1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.gray90)

                Text("여행과 스포츠를 사랑하는 액티비티 러버 ⛷️")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray60)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 16)
    }

    var statsSection: some View {
        HStack(spacing: 0) {
            statItem(count: "\(viewModel.state.myKeeps.count)", label: "액티비티")
            Divider().frame(height: 36)
            statItem(count: "1.2K", label: "팔로워")
            Divider().frame(height: 36)
            statItem(count: "348", label: "팔로잉")
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
    }

    func statItem(count: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(count)
                .font(.Pretendard.body1)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray90)
            Text(label)
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.gray45)
        }
        .frame(maxWidth: .infinity)
    }

    var actionButtons: some View {
        HStack(spacing: 8) {
            actionButton(title: "팔로우", isPrimary: true)
            actionButton(title: "메시지", isPrimary: false)
            actionButton(title: "공유", isPrimary: false)
        }
    }

    func actionButton(title: String, isPrimary: Bool) -> some View {
        Button {
        } label: {
            Text(title)
                .font(.Pretendard.caption1)
                .fontWeight(.semibold)
                .foregroundStyle(isPrimary ? Color.gray0 : Color.gray90)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(isPrimary ? Color.blackSeafoam : Color.gray15)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(filters.enumerated()), id: \.offset) { index, filter in
                    Button {
                        selectedFilter = index
                    } label: {
                        Text(filter)
                            .font(.Pretendard.caption1)
                            .fontWeight(selectedFilter == index ? .semibold : .regular)
                            .foregroundStyle(selectedFilter == index ? Color.gray0 : Color.gray60)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedFilter == index ? Color.blackSeafoam : Color.gray15)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var contentGrid: some View {
        VStack(spacing: 16) {
            if viewModel.state.isLoading && viewModel.state.myKeeps.isEmpty {
                ForEach(0..<4, id: \.self) { _ in
                    profilePlaceholderCard
                }
            } else if viewModel.state.myKeeps.isEmpty {
                Text("저장한 액티비티가 없습니다")
                    .font(.Pretendard.body3)
                    .foregroundStyle(Color.gray45)
                    .padding(.vertical, 40)
            } else {
                ForEach(viewModel.state.myKeeps, id: \.activityId) { activity in
                    profileActivityCard(activity)
                }
            }
        }
    }

    func profileActivityCard(_ activity: ActivitySummaryDTO) -> some View {
        NavigationLink(destination: DetailView(activity: activity)) {
        HStack(spacing: 12) {
            activityThumbnail(activity)
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.Pretendard.body3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.rosyPunch)
                    Text("\(activity.keepCount)개")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)

                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.blackSeafoam)
                        .padding(.leading, 4)
                    Text("\(activity.pointReward)P")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                }

                Text(activity.price.final.wonFormatted)
                    .font(.Pretendard.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blackSeafoam)

                if activity.price.original > activity.price.final {
                    let discount = Int(Double(activity.price.original - activity.price.final) / Double(activity.price.original) * 100)
                    Text("\(discount)% 할인")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.rosyPunch)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray15, lineWidth: 1)
        )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    func activityThumbnail(_ activity: ActivitySummaryDTO) -> some View {
        if let thumbnail = activity.thumbnails.first {
            KFImage(thumbnail.serverImageURL)
                .requestModifier(AuthImageModifier())
                .placeholder { thumbnailPlaceholder }
                .resizable()
                .scaledToFill()
        } else {
            thumbnailPlaceholder
        }
    }

    var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray15)
            .overlay(
                Image(systemName: "photo")
                    .foregroundStyle(Color.gray30)
            )
    }

    var profilePlaceholderCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray15)
                .frame(width: 90, height: 90)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray15).frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Color.gray15).frame(width: 80, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.gray15).frame(width: 100, height: 12)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray15, lineWidth: 1))
    }
}

