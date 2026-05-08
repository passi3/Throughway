
//  ActivityView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher

struct ActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActivityViewModel()
    @State private var selectedFilter: Int = 0
    @State private var isSearchPresented = false

    private let filters = ["주변 액티비티", "인기순", "최신순", "가격순"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroHeader

                    filterChips
                        .padding(.top, 12)

                    activityList
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 20)
                }
            }
            .background(Color.gray0)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        AppIcon.back
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                            .foregroundStyle(Color.gray90)
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("EXCITING")
                        .font(.Paperlogy.caption1)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.blackSeafoam)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isSearchPresented = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.gray90)
                    }
                }
            }
            .fullScreenCover(isPresented: $isSearchPresented) {
                ActivitySearchView()
            }
            .sheet(isPresented: Binding(
                get: { viewModel.state.webViewURL != nil },
                set: { if !$0 { viewModel.send(.webViewDismissed) } }
            )) {
                if let url = viewModel.state.webViewURL {
                    BannerWebViewController(url: url)
                }
            }
        }
        .task {
            viewModel.send(.onAppear)
        }
    }
}

// MARK: - Sections

private extension ActivityView {

    var heroHeader: some View {
        Group {
            if viewModel.state.banners.isEmpty {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blackSeafoam, Color.deepSeafoam],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(2, contentMode: .fit)
            } else {
                TabView {
                    ForEach(viewModel.state.banners.indices, id: \.self) { index in
                        KFImage(viewModel.state.banners[index].imageUrl.serverImageURL)
                            .requestModifier(AuthImageModifier())
                            .resizable()
                            .scaledToFit()
                            .onTapGesture { viewModel.send(.bannerTapped(viewModel.state.banners[index])) }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: viewModel.state.banners.count > 1 ? .automatic : .never))
                .aspectRatio(4, contentMode: .fit)
            }
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

    var activityList: some View {
        VStack(spacing: 16) {
            if viewModel.state.isLoading && viewModel.state.activities.isEmpty {
                ForEach(0..<4, id: \.self) { _ in
                    activityPlaceholderCard
                }
            } else if viewModel.state.activities.isEmpty {
                Text("액티비티가 없습니다")
                    .font(.Pretendard.body3)
                    .foregroundStyle(Color.gray45)
                    .padding(.vertical, 40)
            } else {
                ForEach(viewModel.state.activities, id: \.activityId) { activity in
                    let override = viewModel.state.keepOverrides[activity.activityId]
                    let displayed = override.map {
                        ActivitySummaryDTO(activity, isKeep: $0.isKeep, keepCount: $0.keepCount)
                    } ?? activity
                    NavigationLink(destination: DetailView(activity: displayed)) {
                        ActivityCard(activity: displayed, onKeepTapped: {
                            viewModel.send(.keepToggled(activityId: activity.activityId))
                        })
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var activityPlaceholderCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray15)
                .frame(width: 100, height: 100)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.gray15).frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Color.gray15).frame(width: 80, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.gray15).frame(width: 120, height: 12)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray15, lineWidth: 1))
    }
}

// MARK: - ActivityCard

struct ActivityCard: View {
    let activity: ActivitySummaryDTO
    var onKeepTapped: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            activityThumbnail
                .frame(width: 100, height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(activity.title)
                        .font(.Pretendard.body3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        onKeepTapped?()
                    } label: {
                        Image(systemName: activity.isKeep ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(Color.rosyPunch)
                    }
                    .buttonStyle(.borderless)
                }

                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.rosyPunch)
                    Text("\(activity.keepCount)개")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                }

                Text(activity.country)
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray60)
                    .lineLimit(1)

                Text(activity.price.final.wonFormatted)
                    .font(.Pretendard.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blackSeafoam)
            }
        }
        .padding(12)
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray15, lineWidth: 1)
        )
    }

    @ViewBuilder
    private var activityThumbnail: some View {
        if let thumbnail = activity.thumbnails.first {
            MediaThumbnailView(path: thumbnail, height: 100, cornerRadius: 10)
        } else {
            thumbnailPlaceholder
        }
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color.gray15)
            .overlay(
                Image(systemName: "photo")
                    .foregroundStyle(Color.gray30)
            )
    }
}

