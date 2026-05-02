//
//  ProfileViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class ProfileViewModel: BaseViewModel<ProfileFeature.State, ProfileFeature.Intent> {

    private let activityClient: ActivityAPIClient

    init(activityClient: ActivityAPIClient = .live) {
        self.activityClient = activityClient
        super.init(initialState: .init())
    }

    override func send(_ intent: ProfileFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchMyKeeps() }
        }
    }

    private func fetchMyKeeps() async {
        reduce { $0.isLoading = true }
        do {
            let result = try await activityClient.fetchMyKeeps()
            print("[Profile] myKeeps count: \(result.data.count)")
            reduce { $0.myKeeps = result.data }
        } catch {
            print("[Profile] fetchMyKeeps failed: \(error.localizedDescription)")
            reduce { $0.myKeeps = [] }
        }
        reduce { $0.isLoading = false }
    }
}
