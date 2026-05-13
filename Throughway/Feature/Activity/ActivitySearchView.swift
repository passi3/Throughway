//
//  ActivitySearchView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher

struct ActivitySearchView: View {
    @StateObject private var viewModel = ActivitySearchViewModel()
    @State private var keyword: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    searchBar
                    
                    heroHeader
                        .padding(.top, 12)

                    Divider()
                        .background(Color.border)

                    searchContent
                }
            }
            .background(Color.bgPrimary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("EXCITING")
                        .font(.Paperlogy.caption1)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primary)
                }
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

private extension ActivitySearchView {

    var heroHeader: some View {
        Group {
            if viewModel.state.banners.isEmpty {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.primary, Color.primary],
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

    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.textTertiary)

            TextField("2자 이상 입력 후 검색", text: $keyword)
                .font(.Pretendard.body4)
                .foregroundStyle(Color.textPrimary)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    viewModel.send(.searchSubmitted(keyword))
                }

            if !keyword.isEmpty {
                Button {
                    keyword = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.textTertiary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.bgPrimary)
    }

    @ViewBuilder
    var searchContent: some View {
        if viewModel.state.isLoading {
            loadingView
        } else if !viewModel.state.hasSearched {
            emptyPromptView
        } else if viewModel.state.results.isEmpty {
            noResultView
        } else {
            resultList
        }
    }

    var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<4, id: \.self) { _ in
                placeholderCard
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    var emptyPromptView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)
            Text("검색어를 2자 이상 입력하고\nEnter를 눌러 검색하세요")
                .font(.Pretendard.body4)
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    var noResultView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.textTertiary)
            Text("'\(keyword)'에 대한 검색 결과가 없습니다")
                .font(.Pretendard.body4)
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    var resultList: some View {
        VStack(spacing: 0) {
            Text("검색 결과 \(viewModel.state.results.count)건")
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

            VStack(spacing: 12) {
                ForEach(viewModel.state.results, id: \.activityId) { activity in
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
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
        }
    }

    var placeholderCard: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.bgTertiary)
                .frame(width: 100, height: 100)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Color.bgTertiary).frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: 4).fill(Color.bgTertiary).frame(width: 80, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.bgTertiary).frame(width: 120, height: 12)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.bgPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border, lineWidth: 1))
    }
}

// MARK: - Previews

#if DEBUG
#Preview("액티비티 검색 — 정상") {
    ActivitySearchView()
}
#endif
