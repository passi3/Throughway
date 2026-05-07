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
    @State private var hasSelectedCountryFilter = false
    @State private var selectedCreator: UserInfoResponseDTO? = nil
    @State private var chatRoom: ChatRoomDTO? = nil
    @State private var selectedPost: PostDTO? = nil
    @State private var showAllActivities = false
    @State private var relatedActivityCountry: String? = nil
    @State private var relatedActivityCategory: String? = nil
    @State private var homeScrollOffset: CGFloat = 0

    private let categories = ["전체", "투어", "관광", "패키지", "익사이팅", "체험"]
    private let availableFlags: [AppFlag] = [.korea, .japan, .australia, .philippines, .thailand]

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        scrollOffsetReader

                        flagSection
                            .padding(.top, 12)

                        categoryTabs
                            .padding(.top, 12)

                        featuredSection
                            .padding(.top, 20)

                        postsSection
                            .padding(.top, 20)
                    }
                    .padding(.bottom, 88)
                }
                .background(Color.gray0)
                .coordinateSpace(name: "homeScroll")

                if let post = selectedPost {
                    PostDetailOverlayView(
                        post: post,
                        onDismiss: { selectedPost = nil },
                        onUserSelected: { user in
                            selectedCreator = user
                        },
                        onRelatedActivitiesTapped: { country, category in
                            relatedActivityCountry = country
                            relatedActivityCategory = category
                            showAllActivities = true
                        },
                        onCommentCreated: {
                            viewModel.incrementCommentCount(for: post.postId)
                        },
                        onCommentDeleted: {
                            viewModel.decrementCommentCount(for: post.postId)
                        }
                    )
                    .transition(.opacity.animation(.easeInOut(duration: 0.2)))
                    .zIndex(1)
                }

                if shouldShowCreatePostButton {
                    VStack {
                        Spacer()
                        createPostButton
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(0.5)
                    .allowsHitTesting(false)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.86), value: shouldShowCreatePostButton)
            .onPreferenceChange(HomeScrollOffsetKey.self) { homeScrollOffset = $0 }
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
            .navigationDestination(item: $selectedCreator) { creator in
                UserProfileView(
                    user: creator,
                    myUserId: viewModel.state.myUserId,
                    onChatReady: { room in
                        selectedCreator = nil
                        chatRoom = room
                    }
                )
            }
            .navigationDestination(item: $chatRoom) { room in
                ChatDetailView(room: room, myUserId: viewModel.state.myUserId)
            }
            .navigationDestination(isPresented: $showAllActivities) {
                AllActivitiesView(
                    contextCountry: relatedActivityCountry,
                    contextCategory: relatedActivityCategory
                )
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

    var shouldShowCreatePostButton: Bool {
        selectedPost == nil && homeScrollOffset < -24
    }

    var scrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: HomeScrollOffsetKey.self,
                    value: proxy.frame(in: .named("homeScroll")).minY
                )
        }
        .frame(height: 0)
    }

    var createPostButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 15, weight: .semibold))

            Text("포스트 등록")
                .font(.Pretendard.body3)
                .fontWeight(.semibold)
        }
        .foregroundStyle(Color.gray90)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.lightSeafoam)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 6)
    }

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
            sectionHeader(title: "NEW 액티비티", action: "View All") {
                showAllActivities = true
            }

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
                                    Text("₩")
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
                    Button {
                        selectedPost = post
                    } label: {
                        activityPost(post)
                    }
                    .buttonStyle(.plain)
                }

                paginationFooter
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    var paginationFooter: some View {
        if viewModel.state.isLoadingMorePosts {
            ProgressView()
                .padding(.vertical, 12)
        } else if viewModel.state.nextCursor != nil {
            Color.clear
                .frame(height: 20)
                .onAppear {
                    viewModel.send(.loadMorePosts)
                }
        }
    }

    func activityPost(_ post: PostDTO) -> some View {
        let isLiked = viewModel.isLiked(post)
        let likeCount = viewModel.likeCount(for: post)

        return VStack(alignment: .leading, spacing: 0) {
            // 1. 프로필 헤더
            Button {
                selectedCreator = post.creator.asUserInfo
            } label: {
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

                    HStack(spacing: 6) {
                        Text(post.creator.nick)
                            .font(.Pretendard.body3)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.gray90)

                        Text("·")
                            .font(.Pretendard.caption2)
                            .foregroundStyle(Color.gray30)

                        Text(relativeTime(from: post.createdAt))
                            .font(.Pretendard.caption2)
                            .foregroundStyle(Color.gray45)
                    }

                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // 2. 텍스트 (제목 + 내용)
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.Pretendard.body3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)

                Text(post.content)
                    .font(.Pretendard.body3)
                    .foregroundStyle(Color.gray60)
                    .lineLimit(2)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            // 3. 이미지 (1×n 가로 스크롤)
            if !post.files.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(post.files.indices, id: \.self) { index in
                            KFImage(post.files[index].serverImageURL)
                                .requestModifier(AuthImageModifier())
                                .placeholder {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray15)
                                        .overlay(Image(systemName: "photo").foregroundStyle(Color.gray30))
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: post.files.count == 1 ? nil : 200, height: 220)
                                .frame(maxWidth: post.files.count == 1 ? .infinity : nil)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding(.horizontal, 14)
                }
                .padding(.bottom, 12)
            }

            // 4. 카테고리 칩
            if let category = post.category {
                postTagChip(text: category)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }

            // 5. 액션 바
            Divider()
                .background(Color.gray15)

            HStack(spacing: 0) {
                // 좋아요
                Button {
                    viewModel.send(.likeTapped(post))
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(isLiked ? Color.rosyPunch : Color.gray60)
                        Text("\(likeCount)")
                            .font(.Pretendard.caption1)
                            .foregroundStyle(Color.gray60)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)

                Divider().frame(height: 18).background(Color.gray15)

                // 댓글
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.gray60)
                    Text("\(viewModel.commentCount(for: post))")
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                Divider().frame(height: 18).background(Color.gray15)

                // 공유
                Button {
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.gray60)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 8)
        }
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray15, lineWidth: 1)
        )
    }

    func postTagChip(text: String) -> some View {
        Text(text)
            .font(.Pretendard.caption2)
            .foregroundStyle(Color.blackSeafoam)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blackSeafoam.opacity(0.08))
            .clipShape(Capsule())
    }

    func sectionHeader(title: String, action: String, onAction: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
            Spacer()
            if !action.isEmpty {
                Button(action) { onAction?() }
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.blackSeafoam)
            }
        }
        .padding(.horizontal, 16)
    }

    func relativeTime(from dateString: String) -> String {
        guard let date = AppDateFormatter.iso8601.date(from: dateString) else { return dateString }
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
        "\(selectedFlag)-\(selectedCategory)-\(hasSelectedCountryFilter)"
    }

    var selectedCountryFilter: String? {
        hasSelectedCountryFilter ? selectedFlag.queryCountryName : nil
    }

    var selectedCategoryFilter: String? {
        guard selectedCategory > 0, categories.indices.contains(selectedCategory) else { return nil }
        return categories[selectedCategory]
    }
}

private struct HomeScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
