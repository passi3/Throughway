//
//  MoreActivitiesView.swift
//  Throughway
//
//  Created by passi on 5/6/26.
//

import SwiftUI
import Kingfisher

struct MoreActivitiesView: View {
    @StateObject private var viewModel = MoreActivitiesViewModel()
    @State private var isSearchPresented = false
    let contextCountry: String?
    let contextCategory: String?

    private let cardWidth: CGFloat = 173
    private let cardHeight: CGFloat = 240
    private let twoCol = [GridItem(.fixed(173), spacing: 12), GridItem(.fixed(173), spacing: 12)]

    init(contextCountry: String? = nil, contextCategory: String? = nil) {
        self.contextCountry = contextCountry
        self.contextCategory = contextCategory
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroHeader

                contextHeader
                    .padding(.top, 16)

                sectionTitle("추천 액티비티")
                    .padding(.top, contextHeaderIsVisible ? 16 : 16)

                if viewModel.state.isLoading && viewModel.state.recommended.isEmpty {
                    recommendedPlaceholder
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                } else {
                    LazyVGrid(columns: twoCol, spacing: 12) {
                        ForEach(viewModel.state.recommended, id: \.activityId) { activity in
                            let item = viewModel.displayed(activity)
                            NavigationLink(destination: DetailView(activity: item)) {
                                recommendedCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }

                Rectangle()
                    .fill(Color.lightSeafoam)
                    .frame(height: 1)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)

                sectionTitle("익사이팅 액티비티")

                VStack(spacing: 0) {
                    ForEach(Array(viewModel.state.exciting.enumerated()), id: \.element.activityId) { index, activity in
                        let item = viewModel.displayed(activity)
                        NavigationLink(destination: DetailView(activity: item)) {
                            excitingCard(item)
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.state.exciting.count - 1 {
                            Rectangle()
                                .fill(Color.gray15)
                                .frame(height: 1)
                                .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
        }
        .background(Color.gray0)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("EXCITING")
                    .font(.Paperlogy.caption1)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.blackSeafoam)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { isSearchPresented = true } label: {
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
        .task {
            viewModel.send(.onAppear)
        }
    }
}

// MARK: - Hero Banner

private extension MoreActivitiesView {

    var contextHeaderIsVisible: Bool {
        (contextCountry?.isEmpty == false) || (contextCategory?.isEmpty == false)
    }

    @ViewBuilder
    var contextHeader: some View {
        if contextHeaderIsVisible {
            HStack(alignment: .center, spacing: 10) {
                Text("게시글 기준")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray60)

                if let contextCountry, !contextCountry.isEmpty {
                    contextChip(text: contextCountry)
                }

                if let contextCategory, !contextCategory.isEmpty {
                    contextChip(text: contextCategory)
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }

    var heroHeader: some View {
        Group {
            if viewModel.state.banners.isEmpty {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color.blackSeafoam, Color.deepSeafoam],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .aspectRatio(4, contentMode: .fit)
            } else {
                TabView {
                    ForEach(viewModel.state.banners.indices, id: \.self) { index in
                        KFImage(viewModel.state.banners[index].imageUrl.serverImageURL)
                            .requestModifier(AuthImageModifier())
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                viewModel.send(.bannerTapped(viewModel.state.banners[index]))
                            }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: viewModel.state.banners.count > 1 ? .automatic : .never))
                .aspectRatio(4, contentMode: .fit)
            }
        }
    }

    func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.Pretendard.body2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray90)
            Spacer()
        }
        .padding(.horizontal, 20)
    }

    func contextChip(text: String) -> some View {
        Text(text)
            .font(.Pretendard.caption2)
            .foregroundStyle(Color.blackSeafoam)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.blackSeafoam.opacity(0.08))
            .clipShape(Capsule())
    }
}

// MARK: - Recommended (2-column grid)

private extension MoreActivitiesView {

    var recommendedPlaceholder: some View {
        LazyVGrid(columns: twoCol, spacing: 12) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray15)
                    .frame(height: 240)
            }
        }
    }

    func recommendedCard(_ activity: ActivitySummaryDTO) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                thumbnailImage(activity, height: 120, radius: 16)
                activityStatusBadge(activity)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(activity.title)
                    .font(.Pretendard.body3)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.gray90)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.rosyPunch)
                        Text("\(activity.keepCount)개")
                            .font(.Pretendard.caption2)
                            .foregroundStyle(Color.gray60)
                    }
                    if activity.pointReward > 0 {
                        Text("\(activity.pointReward)P")
                            .font(.Pretendard.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.blackSeafoam)
                    }
                }

                if !activity.tags.isEmpty {
                    Text(activity.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                        .lineLimit(2)
                        .lineSpacing(2)
                }

                priceRow(activity.price)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
        }
        .frame(width: cardWidth, height: cardHeight)
        .background(Color.gray0)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray15, lineWidth: 1)
        )
    }
}

// MARK: - Exciting (vertical full-width list)

private extension MoreActivitiesView {

    func excitingCard(_ activity: ActivitySummaryDTO) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image + overlays
            ZStack(alignment: .topLeading) {
                thumbnailImage(activity, height: 180, radius: 12)

                // Top overlay: country badge left + keep + points right
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10))
                        Text(activity.country)
                            .font(.Pretendard.caption2)
                    }
                    .foregroundStyle(Color.gray0)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.35))
                    .clipShape(Capsule())

                    Spacer()

                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.rosyPunch)
                            Text("\(activity.keepCount)개")
                                .font(.Pretendard.caption2)
                                .foregroundStyle(Color.gray0)
                        }
                        if activity.pointReward > 0 {
                            Text("\(activity.pointReward)P")
                                .font(.Pretendard.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.deepSeafoam)
                        }
                    }

                    // AD tag
                    if activity.isAdvertisement {
                        Text("광고")
                            .font(.system(size: 10))
                            .fontWeight(.medium)
                            .foregroundStyle(Color.gray0)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.15))
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.5), lineWidth: 0.5)
                            )
                            .clipShape(Capsule())
                    }
                }
                .padding(10)

                // Status badge bottom-center
                VStack {
                    Spacer()
                    activityStatusBadge(activity)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 10)
                }
            }
            .frame(height: 180)

            // Description area
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Text(activity.title)
                        .font(.Pretendard.body3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                        .lineLimit(1)
                    Spacer()
                    HStack(spacing: 6) {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(Color.rosyPunch)
                            Text("\(activity.keepCount)개")
                                .font(.Pretendard.caption2)
                                .foregroundStyle(Color.gray60)
                        }
                        if activity.pointReward > 0 {
                            Text("\(activity.pointReward)P")
                                .font(.Pretendard.caption2)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.blackSeafoam)
                        }
                    }
                }

                if !activity.tags.isEmpty {
                    Text(activity.tags.map { "#\($0)" }.joined(separator: " "))
                        .font(.Pretendard.caption2)
                        .foregroundStyle(Color.gray45)
                        .lineLimit(3)
                        .lineSpacing(3)
                }

                priceRow(activity.price)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Shared helpers

private extension MoreActivitiesView {

    func thumbnailImage(_ activity: ActivitySummaryDTO, height: CGFloat, radius: CGFloat) -> some View {
        Group {
            if let thumb = activity.thumbnails.first {
                KFImage(thumb.serverImageURL)
                    .requestModifier(AuthImageModifier())
                    .placeholder {
                        imagePlaceholder(radius: radius)
                    }
                    .resizable()
                    .scaledToFill()
            } else {
                imagePlaceholder(radius: radius)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: radius))
    }

    func imagePlaceholder(radius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(Color.gray15)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.gray30)
            )
    }

    @ViewBuilder
    func activityStatusBadge(_ activity: ActivitySummaryDTO) -> some View {
        let isHot = activity.keepCount >= 100
        Text(isHot ? "HOT" : "NEW")
            .font(.Pretendard.caption2)
            .fontWeight(.bold)
            .foregroundStyle(Color.gray0)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(isHot ? Color.rosyPunch : Color.blackSeafoam)
            .clipShape(Capsule())
    }

    func priceRow(_ price: ActivityPriceDTO) -> some View {
        let discountPercent: Int? = {
            guard price.original > 0, price.final < price.original else { return nil }
            return Int(Double(price.original - price.final) / Double(price.original) * 100)
        }()

        return HStack(spacing: 6) {
            Text(price.final.wonFormatted)
                .font(.Pretendard.caption1)
                .fontWeight(.bold)
                .foregroundStyle(Color.blackSeafoam)

            if price.original > 0 && price.original != price.final {
                Text(price.original.wonFormatted)
                    .font(.Pretendard.caption2)
                    .strikethrough()
                    .foregroundStyle(Color.gray45)
            }

            if let pct = discountPercent {
                Text("\(pct)%")
                    .font(.Pretendard.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.rosyPunch)
            }
        }
    }
}
