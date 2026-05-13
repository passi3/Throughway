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
    @State private var showMoreActivities = false
    @State private var relatedActivityCountry: String? = nil
    @State private var relatedActivityCategory: String? = nil
    @State private var homeScrollOffset: CGFloat = 0
    @State private var featuredHeaderOffset: CGFloat = .infinity
    @State private var postsHeaderOffset: CGFloat = .infinity
    @State private var showCreatePost = false
    @State private var editingPost: PostDTO? = nil
    @State private var postToDelete: PostDTO? = nil

    private let categories = ["전체", "투어", "관광", "패키지", "익사이팅", "체험"]
    private let availableFlags: [AppFlag] = [.korea, .japan, .australia, .philippines, .thailand]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                customHeader

                ZStack {
                    ScrollView {
                        VStack(spacing: 0) {
                            scrollOffsetReader

                            flagSection
                                .padding(.top, 12)

                            categoryTabs
                                .padding(.top, 12)

                            featuredOffsetReader
                            featuredSectionHeader
                                .padding(.top, 20)

                            featuredSection
                                .padding(.top, 12)

                            postsOffsetReader
                            postsSectionHeader
                                .padding(.top, 20)

                            postsSection
                        }
                        .padding(.bottom, 88)
                    }
                    .background(Color.bgPrimary)
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
                                showMoreActivities = true
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

                    VStack {
                        Spacer()
                        Button {
                            showCreatePost = true
                        } label: {
                            createPostButton
                        }
                        .buttonStyle(.plain)
                        .scaleEffect(
                            x: shouldShowCreatePostButton ? 1 : 0.01,
                            y: 1,
                            anchor: .center
                        )
                        .opacity(shouldShowCreatePostButton ? 1 : 0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .zIndex(0.5)
                    .allowsHitTesting(shouldShowCreatePostButton)
                }
                .animation(.spring(response: 0.35, dampingFraction: 0.86), value: shouldShowCreatePostButton)
                .onPreferenceChange(ScrollOffsetsKey.self) { offsets in
                    if let s = offsets.scroll { homeScrollOffset = s }
                    if let f = offsets.featured { featuredHeaderOffset = f }
                    if let p = offsets.posts { postsHeaderOffset = p }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
            .navigationDestination(isPresented: $showMoreActivities) {
                MoreActivitiesView(
                    contextCountry: relatedActivityCountry,
                    contextCategory: relatedActivityCategory
                )
            }
            .sheet(isPresented: $showCreatePost, onDismiss: {
                viewModel.send(.refreshPosts)
            }) {
                CreatePostView(
                    latitude: viewModel.currentLatitude,
                    longitude: viewModel.currentLongitude
                )
            }
            .sheet(item: $editingPost, onDismiss: {
                viewModel.send(.refreshPosts)
            }) { post in
                CreatePostView(
                    post: post,
                    latitude: viewModel.currentLatitude,
                    longitude: viewModel.currentLongitude
                )
            }
            .alert("게시글을 삭제할까요?", isPresented: Binding(
                get: { postToDelete != nil },
                set: { if !$0 { postToDelete = nil } }
            )) {
                Button("삭제", role: .destructive) {
                    if let post = postToDelete {
                        viewModel.send(.deletePost(post.postId))
                        postToDelete = nil
                    }
                }
                Button("취소", role: .cancel) { postToDelete = nil }
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

    var customHeader: some View {
        HStack {
            Text(toolbarSectionTitle ?? "Throughway")
                .font(.Pretendard.body1)
                .fontWeight(.bold)
                .foregroundStyle(Color.textPrimary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.25), value: toolbarSectionTitle)

            Spacer()

            Group {
                switch toolbarSectionTitle {
                case "NEW 액티비티":
                    Button("View All") { showMoreActivities = true }
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.primary)
                case "액티비티 포스트":
                    sortOrderMenu
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: toolbarSectionTitle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.bgPrimary)
    }

    var shouldShowCreatePostButton: Bool {
        selectedPost == nil && toolbarSectionTitle == "액티비티 포스트"
    }

    var scrollOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ScrollOffsetsKey.self,
                value: ScrollOffsetData(scroll: proxy.frame(in: .named("homeScroll")).minY)
            )
        }
        .frame(height: 0)
    }

    var createPostButton: some View {
        HStack(spacing: 8) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 15, weight: .semibold))

            Text("포스트 등록")
                .font(.Pretendard.body4)
                .fontWeight(.semibold)
        }
        .foregroundStyle(Color.textPrimary)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color.primaryLight)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 6)
    }

    var sortOrderMenu: some View {
        Menu {
            Button {
                viewModel.send(.sortChanged("createdAt"))
            } label: {
                Label("최신순", systemImage: viewModel.state.sortOrder == "createdAt" ? "checkmark" : "")
            }
            Button {
                viewModel.send(.sortChanged("likes"))
            } label: {
                Label("좋아요순", systemImage: viewModel.state.sortOrder == "likes" ? "checkmark" : "")
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.state.sortOrder == "createdAt" ? "최신순" : "좋아요순")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.textSecondary)
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.textSecondary)
            }
        }
    }

    var toolbarSectionTitle: String? {
        if postsHeaderOffset < 0 { return "액티비티 포스트" }
        if featuredHeaderOffset < 0 { return "NEW 액티비티" }
        return nil
    }

    var featuredOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ScrollOffsetsKey.self,
                value: ScrollOffsetData(featured: proxy.frame(in: .named("homeScroll")).minY)
            )
        }
        .frame(height: 0)
    }

    var postsOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear.preference(
                key: ScrollOffsetsKey.self,
                value: ScrollOffsetData(posts: proxy.frame(in: .named("homeScroll")).minY)
            )
        }
        .frame(height: 0)
    }

    var featuredSectionHeader: some View {
        HStack {
            Text("NEW 액티비티")
                .font(.Pretendard.body3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            Button("View All") { showMoreActivities = true }
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.primary)
        }
        .padding(.horizontal, 16)
    }

    var postsSectionHeader: some View {
        HStack {
            Text("액티비티 포스트")
                .font(.Pretendard.body3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            sortOrderMenu
        }
        .padding(.horizontal, 16)
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
                                .font(.Pretendard.caption2)
                                .foregroundStyle(selectedFlag == flag ? Color.bgPrimary : Color.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(selectedFlag == flag ? Color.primary : Color.bgTertiary)
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
                            .font(.Pretendard.body4)
                            .fontWeight(selectedCategory == index ? .semibold : .regular)
                            .foregroundStyle(selectedCategory == index ? Color.bgPrimary : Color.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedCategory == index ? Color.primary : Color.bgTertiary)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }

    var featuredSection: some View {
        VStack(spacing: 0) {
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
                        MediaThumbnailView(path: thumbnail, height: 340, cornerRadius: 0)
                            .frame(width: 260)
                    } else {
                        cardImagePlaceholder
                            .frame(width: 260, height: 340)
                    }
                }
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
                            .font(.Pretendard.caption3)
                    }
                    .foregroundStyle(Color.bgPrimary)
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
                            .foregroundStyle(Color.bgPrimary)
                            .lineLimit(2)

                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Text("₩")
                                        .font(.system(size: 9))
                                        .foregroundStyle(Color.bgPrimary)
                                )
                            Text(activity.price.final.wonFormatted)
                                .font(.Pretendard.body4)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.bgPrimary)
                        }

                        if !activity.tags.isEmpty {
                            Text(activity.tags.map { "#\($0)" }.joined(separator: " "))
                                .font(.Pretendard.caption3)
                                .foregroundStyle(Color.bgPrimary.opacity(0.8))
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
            .fill(Color.bgTertiary)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.textTertiary)
            )
    }

    var featuredPlaceholderCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.bgTertiary)
            .frame(width: 260, height: 340)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.textTertiary)
            )
    }

    var featuredEmptyCard: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.bgTertiary)
            .frame(width: 260, height: 340)
            .overlay(
                Text("신규 액티비티가 없습니다")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.textTertiary)
            )
    }

    // MARK: Posts section (distance slider + feed)

    var postsSection: some View {
        VStack(spacing: 0) {
            // Distance slider
            VStack(spacing: 8) {
                HStack {
                    Text(viewModel.state.isDistanceEnabled
                         ? String(format: "Distance %.0fKM", viewModel.state.distanceKm)
                         : "Distance 전체")
                        .font(.Pretendard.body4)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primary)
                    Spacer()
                }
                .padding(.horizontal, 16)

                HStack(spacing: 12) {
                    Button {
                        viewModel.send(.distanceToggled)
                    } label: {
                        Image(systemName: viewModel.state.isDistanceEnabled ? "location.fill" : "location.slash.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(viewModel.state.isDistanceEnabled ? Color.bgPrimary : Color.textTertiary)
                            .frame(width: 36, height: 36)
                            .background(viewModel.state.isDistanceEnabled ? Color.primary : Color.bgTertiary)
                            .clipShape(Circle())
                    }

                    Slider(
                        value: Binding(
                            get: { viewModel.state.distanceKm },
                            set: { viewModel.send(.distanceChanged($0)) }
                        ),
                        in: 1...50,
                        step: 1
                    )
                    .tint(Color.primary)
                    .disabled(!viewModel.state.isDistanceEnabled)
                    .opacity(viewModel.state.isDistanceEnabled ? 1 : 0.3)
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 12)

            // Feed
            activityFeed
                .padding(.top, 16)
        }
    }

    var activityFeed: some View {
        LazyVStack(spacing: 16) {
            if viewModel.state.geoPosts.isEmpty {
                Text("주변 게시물이 없습니다")
                    .font(.Pretendard.body4)
                    .foregroundStyle(Color.textTertiary)
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
            HStack(spacing: 0) {
                Button {
                    selectedCreator = post.creator.asUserInfo
                } label: {
                    HStack(spacing: 10) {
                        KFImage(post.creator.profileImage.flatMap { $0.serverImageURL })
                            .requestModifier(AuthImageModifier())
                            .placeholder {
                                Circle()
                                    .fill(Color.bgTertiary)
                                    .overlay(Image(systemName: "person.fill").foregroundStyle(Color.textTertiary))
                            }
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())

                        HStack(spacing: 6) {
                            Text(post.creator.nick)
                                .font(.Pretendard.body4)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.textPrimary)

                            Text("·")
                                .font(.Pretendard.caption3)
                                .foregroundStyle(Color.textTertiary)

                            Text(relativeTime(from: post.createdAt))
                                .font(.Pretendard.caption3)
                                .foregroundStyle(Color.textTertiary)
                        }

                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                if post.creator.userId == AppSession.userId {
                    Menu {
                        Button("수정") { editingPost = post }
                        Button("삭제", role: .destructive) { postToDelete = post }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.textTertiary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

            // 2. 텍스트 (제목 + 내용)
            VStack(alignment: .leading, spacing: 4) {
                Text(post.title)
                    .font(.Pretendard.body4)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.textPrimary)

                Text(post.content)
                    .font(.Pretendard.body4)
                    .foregroundStyle(Color.textSecondary)
                    .lineLimit(2)
                    .lineSpacing(2)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

            // 3. 첫 번째 미디어만 표시 (나머지는 PostDetailOverlayView에서 확인)
            if let firstFile = post.files.first {
                MediaThumbnailView(path: firstFile, height: 220, cornerRadius: 8, allowsFullscreen: false)
                    .padding(.horizontal, 14)
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
                .background(Color.border)

            HStack(spacing: 0) {
                // 좋아요
                Button {
                    viewModel.send(.likeTapped(post))
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 16))
                            .foregroundStyle(isLiked ? Color.error : Color.textSecondary)
                        Text("\(likeCount)")
                            .font(.Pretendard.caption2)
                            .foregroundStyle(Color.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)

                Divider().frame(height: 18).background(Color.border)

                // 댓글
                HStack(spacing: 5) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                    Text("\(viewModel.commentCount(for: post))")
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)

                Divider().frame(height: 18).background(Color.border)

                // 공유
                Button {
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 8)
        }
        .background(Color.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.border, lineWidth: 1)
        )
    }

    func postTagChip(text: String) -> some View {
        Text(text)
            .font(.Pretendard.caption3)
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.primary.opacity(0.08))
            .clipShape(Capsule())
    }

    func sectionHeader(title: String, action: String, onAction: (() -> Void)? = nil) -> some View {
        HStack {
            Text(title)
                .font(.Pretendard.body3)
                .fontWeight(.semibold)
                .foregroundStyle(Color.textPrimary)
            Spacer()
            if !action.isEmpty {
                Button(action) { onAction?() }
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.primary)
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

extension PostDTO: @retroactive Identifiable {
    public var id: String { postId }
}

private struct ScrollOffsetData: Equatable {
    var scroll: CGFloat?
    var featured: CGFloat?
    var posts: CGFloat?
}

private struct ScrollOffsetsKey: PreferenceKey {
    static var defaultValue = ScrollOffsetData()

    static func reduce(value: inout ScrollOffsetData, nextValue: () -> ScrollOffsetData) {
        let next = nextValue()
        if let s = next.scroll { value.scroll = s }
        if let f = next.featured { value.featured = f }
        if let p = next.posts { value.posts = p }
    }
}
