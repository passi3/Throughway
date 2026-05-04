//
//  UserSearchViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class UserSearchViewModel: BaseViewModel<UserSearchFeature.State, UserSearchFeature.Intent> {

    private let userAPIClient: UserAPIClient

    init(userAPIClient: UserAPIClient = .live) {
        self.userAPIClient = userAPIClient
        super.init(initialState: .init())
    }

    override func send(_ intent: UserSearchFeature.Intent) {
        switch intent {
        case .queryChanged(let query):
            reduce { $0.query = query }

        case .searchSubmitted:
            Task { await search() }
        }
    }

    private func search() async {
        let q = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }

        reduce { $0.isLoading = true; $0.hasSearched = false }
        defer { reduce { $0.isLoading = false } }

        do {
            let result = try await userAPIClient.searchUserInfo(q)
            reduce { $0.results = result.data; $0.hasSearched = true }
        } catch {
            print("[UserSearch] search failed: \(error.localizedDescription)")
            reduce { $0.results = []; $0.hasSearched = true }
        }
    }
}
