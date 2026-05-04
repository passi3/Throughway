//
//  UserSearchView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI
import Kingfisher

struct UserSearchView: View {
    let myUserId: String
    let onChatReady: (ChatRoomDTO) -> Void

    @StateObject private var viewModel = UserSearchViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar
                Divider()
                resultContent
            }
            .background(Color.gray0)
            .navigationTitle("사용자 검색")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(Color.gray60)
                }
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.gray45)

            TextField("닉네임 검색", text: Binding(
                get: { viewModel.state.query },
                set: { viewModel.send(.queryChanged($0)) }
            ))
            .font(.Pretendard.body2)
            .submitLabel(.search)
            .onSubmit { viewModel.send(.searchSubmitted) }

            if !viewModel.state.query.isEmpty {
                Button {
                    viewModel.send(.queryChanged(""))
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Color.gray45)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.gray15)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Result Content

    @ViewBuilder
    private var resultContent: some View {
        if viewModel.state.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.state.hasSearched && viewModel.state.results.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "person.slash")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.gray45)
                Text("검색 결과가 없습니다")
                    .font(.Pretendard.body2)
                    .foregroundStyle(Color.gray45)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(viewModel.state.results, id: \.userId) { user in
                NavigationLink {
                    UserProfileView(
                        user: user,
                        myUserId: myUserId,
                        onChatReady: onChatReady
                    )
                } label: {
                    UserSearchRowView(user: user, query: viewModel.state.query)
                }
                .listRowBackground(Color.gray0)
                .listRowSeparatorTint(Color.gray15)
            }
            .listStyle(.plain)
        }
    }
}

// MARK: - Row

private struct UserSearchRowView: View {
    let user: UserInfoResponseDTO
    let query: String

    var body: some View {
        HStack(spacing: 12) {
            profileImage
            VStack(alignment: .leading, spacing: 4) {
                highlightedNick
                if let intro = user.introduction, !intro.isEmpty {
                    Text(intro)
                        .font(.Pretendard.caption1)
                        .foregroundStyle(Color.gray60)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var profileImage: some View {
        Group {
            if let path = user.profileImage, let url = path.serverImageURL {
                KFImage(url)
                    .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 44, height: 44)))
                    .requestModifier(AuthImageModifier())
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .foregroundStyle(Color.gray30)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }

    private var highlightedNick: some View {
        Text(attributedNick)
            .font(.Pretendard.body2)
    }

    private var attributedNick: AttributedString {
        var attributed = AttributedString(user.nick)
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty,
              let range = attributed.range(of: q, options: .caseInsensitive) else {
            return attributed
        }
        attributed[range].font = .system(size: 15, weight: .bold)
        attributed[range].foregroundColor = UIColor(Color.blackSeafoam)
        return attributed
    }
}
