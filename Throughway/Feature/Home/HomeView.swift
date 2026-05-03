//
//  HomeView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher

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

                    postsSection
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
            HStack(spacing: 8) {
                ForEach(Array(categories.enumerated()), id: \.offset) { index, category in
                    Button {
                        hasSelectedCategoryFilter = true
                        selectedCategory = index
                    } label: {
                        Text(category)
                            .font(.Pretendard.body3)
                            .fontWeight(selectedCategory == index ? .semibold : .regular)
                            .foregroundStyle(selectedCategory == index ? Color.gray0 : Color.gray60)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedCategory == index ? Color.blackSeafoam : Color.gray15)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var featuredSection: some View {
        VStack(spacing: 12) {
            sectionHeader(title: "NEW 액티비티", action: "View All")

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
        NavigationLink(destination: DetailView(activity: activity)) {
            ZStack {
                // Background image
                Group {
                    if let thumbnail = activity.thumbnails.first {
                        KFImage(thumbnail.serverImageURL)
                            .requestModifier(AuthImageModifier())
                            .placeholder { cardImagePlaceholder }
                            .resizable()
                            .scaledToFill()
                    } else {
                        cardImagePlaceholder
                    }
                }
                .frame(width: 260, height: 340)
                .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.black.opacity(0.15), .black.opacity(0.75)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                VStack(alignment: .leading, spacing: 0) {
                    // Location badge
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                        Text(activity.country)
                            .font(.Pretendard.caption2)
                    }
                    .foregroundStyle(Color.gray0)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())

                    Spacer()

                    // Bottom content
                    VStack(alignment: .leading, spacing: 8) {
                        Text(activity.title)
                            .font(.Pretendard.title1)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.gray0)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.blackSeafoam)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Image(systemName: "won.sign")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.gray0)
                                )
                            Text(activity.price.final.wonFormatted)
                                .font(.Pretendard.body3)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.gray0)
                        }

                        if !activity.tags.isEmpty {
                            Text(activity.tags.map { "#\($0)" }.joined(separator: " "))
                                .font(.Pretendard.caption2)
                                .foregroundStyle(Color.gray0.opacity(0.8))
                                .lineLimit(3)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding(14)
                .frame(width: 260, alignment: .leading)
            }
            .frame(width: 260, height: 340)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    var cardImagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray15)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.gray30)
            )
    }

    var featuredPlaceholderCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray15)
            .frame(width: 260, height: 340)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.gray30)
            )
    }

    var featuredEmptyCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.gray15)
            .frame(width: 260, height: 340)
            .overlay(
                Text("신규 액티비티가 없습니다")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
            )
    }

    // MARK: Posts section (distance slider + feed)

    var postsSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("액티비티 포스트")
                    .font(.Pretendard.body2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)
                Spacer()
                Button {
                } label: {
                    HStack(spacing: 4) {
                        Text("최신순")
                            .font(.Pretendard.caption1)
                            .foregroundStyle(Color.gray60)
                        Image(systemName: "line.3.horizontal")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.gray60)
                    }
                }
            }
            .padding(.horizontal, 16)

            // Distance slider
            VStack(spacing: 8) {
                HStack {
                    Text(String(format: "Distance %.0fKM", viewModel.state.distanceKm))
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
                    in: 0...5,
                    step: 1
                )
                .tint(Color.blackSeafoam)
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)

            // Feed
            activityFeed
                .padding(.top, 16)
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
        VStack(alignment: .leading, spacing: 12) {
            // Creator row
            HStack(spacing: 10) {
                KFImage(post.creator.profileImage.flatMap { $0.serverImageURL })
                    .requestModifier(AuthImageModifier())
                    .placeholder {
                        Circle()
                            .fill(Color.gray15)
                            .overlay(Image(systemName: "person.fill").foregroundStyle(Color.gray45))
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(post.creator.nick)
                        .font(.Pretendard.body3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                    Text(relativeTime(from: post.createdAt))
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                }

                Spacer()
            }

            // Image grid
            postImageGrid(post)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            // Title
            Text(post.title)
                .font(.Pretendard.body2)
                .fontWeight(.bold)
                .foregroundStyle(Color.gray90)

            // Content
            Text(post.content)
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray75)
                .lineLimit(2)
                .lineSpacing(3)

            // Tag chips
            if post.country != nil || post.category != nil {
                HStack(spacing: 6) {
                    if let country = post.country {
                        postTagChip(text: country, icon: "mappin")
                    }
                    if let category = post.category {
                        postTagChip(text: category, icon: nil)
                    }
                }
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

    @ViewBuilder
    func postImageGrid(_ post: PostDTO) -> some View {
        let files = post.files
        let isLiked = viewModel.isLiked(post)

        if files.isEmpty {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray15)
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .overlay(
                    Image(systemName: "photo")
                        .font(.system(size: 36))
                        .foregroundStyle(Color.gray30)
                )
        } else if files.count == 1 {
            singlePostImage(files[0], isLiked: isLiked, post: post)
                .frame(maxWidth: .infinity, maxHeight: 200)
        } else {
            GeometryReader { geo in
                HStack(spacing: 3) {
                    // Main image (left 2/3)
                    ZStack(alignment: .topLeading) {
                        KFImage(files[0].serverImageURL)
                            .requestModifier(AuthImageModifier())
                            .placeholder { postImagePlaceholder }
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width * 2/3, height: 200)
                            .clipped()

                        // Heart overlay
                        Button {
                            viewModel.send(.likeTapped(post))
                        } label: {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 16))
                                .foregroundStyle(isLiked ? Color.rosyPunch : Color.gray0)
                                .padding(8)
                        }

                        // Play button center
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color.gray0.opacity(0.85))
                            .frame(width: geo.size.width * 2/3, height: 200)
                    }
                    .frame(width: geo.size.width * 2/3, height: 200)

                    // Right column (1/3)
                    VStack(spacing: 3) {
                        KFImage(files[1].serverImageURL)
                            .requestModifier(AuthImageModifier())
                            .placeholder { postImagePlaceholder }
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width / 3, height: 98)
                            .clipped()

                        if files.count >= 3 {
                            KFImage(files[2].serverImageURL)
                                .requestModifier(AuthImageModifier())
                                .placeholder { postImagePlaceholder }
                                .resizable()
                                .scaledToFill()
                                .frame(width: geo.size.width / 3, height: 98)
                                .clipped()
                        } else {
                            postImagePlaceholder
                                .frame(width: geo.size.width / 3, height: 98)
                        }
                    }
                    .frame(width: geo.size.width / 3)
                }
            }
            .frame(height: 200)
        }
    }

    func singlePostImage(_ path: String, isLiked: Bool, post: PostDTO) -> some View {
        ZStack(alignment: .topLeading) {
            KFImage(path.serverImageURL)
                .requestModifier(AuthImageModifier())
                .placeholder { postImagePlaceholder }
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipped()

            Button {
                viewModel.send(.likeTapped(post))
            } label: {
                Image(systemName: isLiked ? "heart.fill" : "heart")
                    .font(.system(size: 16))
                    .foregroundStyle(isLiked ? Color.rosyPunch : Color.gray0)
                    .padding(8)
            }

            Image(systemName: "play.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color.gray0.opacity(0.85))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    var postImagePlaceholder: some View {
        Rectangle()
            .fill(Color.gray15)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.gray30)
            )
    }

    func postTagChip(text: String, icon: String?) -> some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundStyle(Color.blackSeafoam)
            }
            Text(text)
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.gray75)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray15)
        .clipShape(Capsule())
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

    func relativeTime(from dateString: String) -> String {
        guard let date = AppFormatter.iso8601.date(from: dateString) else { return dateString }
        let elapsed = Date().timeIntervalSince(date)
        if elapsed < 60 { return "방금 전" }
        if elapsed < 3600 { return "\(Int(elapsed / 60))분 전" }
        if elapsed < 86400 { return "\(Int(elapsed / 3600))시간 전" }
        return "\(Int(elapsed / 86400))일 전"
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
