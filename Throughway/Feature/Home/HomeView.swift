//
//  HomeView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedCategory: Int = 0
    @State private var selectedFlag: AppFlag = .korea
    @State private var hasSelectedCategoryFilter = false
    @State private var hasSelectedCountryFilter = false

    private let categories = ["투어", "관광", "패키지", "익사이팅", "체험"]
    private let availableFlags: [AppFlag] = [.korea, .japan, .australia, .philippines, .thailand]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    flagSection
                        .padding(.top, 12)

                    categoryTabs
                        .padding(.top, 12)

                    featuredSection
                        .padding(.top, 20)

                    distanceSection
                        .padding(.top, 20)

                    activityFeed
                        .padding(.top, 20)
                }
                .padding(.bottom, 20)
            }
            .background(Color.gray0)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("SeSAC ACTIVITY")
                        .font(.Paperlogy.caption1)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.blackSeafoam)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                        } label: {
                            AppIcon.notification
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(Color.gray90)
                        }
                        Button {
                        } label: {
                            AppIcon.search
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                                .foregroundStyle(Color.gray90)
                        }
                    }
                }
            }
        }
        .task {
            viewModel.send(.start)
        }
        .task(id: featuredRequestID) {
            viewModel.send(.fetchNewActivities(country: selectedCountryFilter, category: selectedCategoryFilter))
        }
    }
}

// MARK: - Sections

private extension HomeView {

    var flagSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(availableFlags, id: \.self) { flag in
                    Button {
                        hasSelectedCountryFilter = true
                        selectedFlag = flag
                    } label: {
                        HStack(spacing: 6) {
                            flag.image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 2))

                            Text(flag.shortName)
                                .font(.Pretendard.caption1)
                                .foregroundStyle(selectedFlag == flag ? Color.gray0 : Color.gray75)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedFlag == flag ? Color.blackSeafoam : Color.gray15)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    Button {
                        hasSelectedCategoryFilter = true
                        selectedCategory = index
                    } label: {
                        VStack(spacing: 6) {
                            Text(category)
                                .font(.Pretendard.body3)
                                .fontWeight(selectedCategory == index ? .semibold : .regular)
                                .foregroundStyle(selectedCategory == index ? Color.blackSeafoam : Color.gray45)

                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(selectedCategory == index ? Color.blackSeafoam : Color.clear)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray15)
        }
    }

    var featuredSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "신규 액티비티", action: "View All")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    if viewModel.state.isLoadingNewActivities && viewModel.state.newActivities.isEmpty {
                        ForEach(0..<5, id: \.self) { _ in
                            featuredPlaceholderCard
                        }
                    } else if viewModel.state.newActivities.isEmpty {
                        featuredEmptyCard
                    } else {
                        ForEach(viewModel.state.newActivities, id: \.activityId) { activity in
                            featuredCard(activity)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    func featuredCard(_ activity: ActivitySummaryDTO) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            featuredThumbnail(activity)
                .frame(width: 240, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(activity.title)
                .font(.Pretendard.body3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
                .lineLimit(1)

            Text(activity.country)
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.gray45)

            HStack(spacing: 4) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color.rosyPunch)
                Text("\(activity.keepCount)개")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.gray45)
                Spacer()
                Text(activity.price.final.wonFormatted)
                    .font(.Pretendard.caption1)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.blackSeafoam)
            }
        }
        .frame(width: 240)
    }

    @ViewBuilder
    func featuredThumbnail(_ activity: ActivitySummaryDTO) -> some View {
        if let thumbnail = activity.thumbnails.first,
           let url = URL(string: thumbnail) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                thumbnailPlaceholder
            }
        } else {
            thumbnailPlaceholder
        }
    }

    var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray15)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.gray30)
            )
    }

    var featuredPlaceholderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray15)
                .frame(width: 240, height: 160)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 32))
                        .foregroundStyle(Color.gray30)
                )

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray15)
                .frame(width: 160, height: 14)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray15)
                .frame(width: 80, height: 12)
        }
        .frame(width: 240)
    }

    var featuredEmptyCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray15)
                .frame(width: 240, height: 160)
                .overlay(
                    Text("신규 액티비티가 없습니다")
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray45)
                )

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.clear)
                .frame(width: 240, height: 14)
        }
        .frame(width: 240)
    }

    var distanceSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "내 주변 게시물", action: "")

            VStack(spacing: 8) {
                HStack {
                    Text(String(format: "%.0fKM", viewModel.state.distanceKm))
                        .font(.Pretendard.body3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.blackSeafoam)
                    Spacer()
                }
                .padding(.horizontal, 16)

                Slider(
                    value: Binding(
                        get: { viewModel.state.distanceKm },
                        set: { viewModel.send(.distanceChanged($0)) }
                    ),
                    in: 0...100,
                    step: 1
                )
                .tint(Color.blackSeafoam)
                .padding(.horizontal, 16)
            }
        }
    }

    var activityFeed: some View {
        VStack(spacing: 16) {
            if viewModel.state.geoPosts.isEmpty {
                Text("주변 게시물이 없습니다")
                    .font(.Pretendard.body3)
                    .foregroundStyle(Color.gray45)
                    .padding(.vertical, 40)
            } else {
                ForEach(viewModel.state.geoPosts, id: \.postId) { post in
                    activityPost(post)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    func activityPost(_ post: PostDTO) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color.gray15)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(Color.gray45)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.creator.nick)
                        .font(.Pretendard.body3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                    Text(post.createdAt)
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                }

                Spacer()
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray15)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray30)
                )

            Text(post.content)
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray75)
                .lineLimit(2)

            HStack(spacing: 16) {
                let isLiked = viewModel.isLiked(post)
                let displayCount = viewModel.likeCount(for: post)

                Button {
                    viewModel.send(.likeTapped(post))
                } label: {
                    Label("\(displayCount)", systemImage: isLiked ? "heart.fill" : "heart")
                        .font(.Pretendard.caption1)
                        .foregroundStyle(isLiked ? Color.rosyPunch : Color.gray45)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray15, lineWidth: 1)
        )
    }

    func sectionHeader(title: String, action: String) -> some View {
        HStack {
            Text(title)
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
            Spacer()
            if !action.isEmpty {
                Button(action) {}
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.blackSeafoam)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - AppFlag extension

private extension AppFlag {
    var shortName: String {
        switch self {
        case .korea:       return "대한민국"
        case .japan:       return "일본"
        case .philippines: return "필리핀"
        case .thailand:    return "태국"
        case .taiwan:      return "대만"
        case .argentina:   return "아르헨"
        case .australia:   return "호주"
        }
    }

    var queryCountryName: String {
        switch self {
        case .korea:       return "대한민국"
        case .japan:       return "일본"
        case .philippines: return "필리핀"
        case .thailand:    return "태국"
        case .taiwan:      return "대만"
        case .argentina:   return "아르헨티나"
        case .australia:   return "호주"
        }
    }
}

private extension HomeView {
    var featuredRequestID: String {
        "\(selectedFlag)-\(selectedCategory)-\(hasSelectedCountryFilter)-\(hasSelectedCategoryFilter)"
    }

    var selectedCountryFilter: String? {
        hasSelectedCountryFilter ? selectedFlag.queryCountryName : nil
    }

    var selectedCategoryFilter: String? {
        hasSelectedCategoryFilter ? selectedCategoryName : nil
    }

    var selectedCategoryName: String? {
        categories.indices.contains(selectedCategory) ? categories[selectedCategory] : nil
    }
}

// MARK: - Price formatter

private extension Int {
    var wonFormatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return (formatter.string(from: NSNumber(value: self)) ?? "\(self)") + "원"
    }
}

#Preview {
    HomeView()
}
