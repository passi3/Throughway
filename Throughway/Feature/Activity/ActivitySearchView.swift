//
//  ActivitySearchView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI

struct ActivitySearchView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ActivitySearchViewModel()
    @State private var keyword: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                Divider()
                    .background(Color.gray15)

                searchContent
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
                    Text("액티비티 검색")
                        .font(.Pretendard.body3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.gray90)
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

// MARK: - Sections

private extension ActivitySearchView {

    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(Color.gray45)

            TextField("2자 이상 입력 후 검색", text: $keyword)
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray90)
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
                        .foregroundStyle(Color.gray30)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray0)
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
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<4, id: \.self) { _ in
                    placeholderCard
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }

    var emptyPromptView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.gray30)
            Text("검색어를 2자 이상 입력하고\nEnter를 눌러 검색하세요")
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray45)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var noResultView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(Color.gray30)
            Text("'\(keyword)'에 대한 검색 결과가 없습니다")
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray45)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var resultList: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text("검색 결과 \(viewModel.state.results.count)건")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray45)
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
    }

    var placeholderCard: some View {
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
