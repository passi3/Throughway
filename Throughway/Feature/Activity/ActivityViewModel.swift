//
//  ActivityViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class ActivityViewModel: BaseViewModel<ActivityFeature.State, ActivityFeature.Intent> {

    private let activityClient: ActivityAPIClient
    private let bannerClient: BannerAPIClient

    init(activityClient: ActivityAPIClient = .live, bannerClient: BannerAPIClient = .live) {
        self.activityClient = activityClient
        self.bannerClient = bannerClient
        super.init(initialState: .init())
    }

    override func send(_ intent: ActivityFeature.Intent) {
        switch intent {
        case .onAppear:
            Task {
                async let fetchList: () = fetchList()
                async let fetchBanners: () = fetchBanners()
                _ = await (fetchList, fetchBanners)
            }

        case .bannerTapped(let banner):
            guard banner.payload.type == "WEBVIEW",
                  let url = URL(string: APIConstants.baseURL + banner.payload.value) else { return }
            reduce { $0.webViewURL = url }

        case .webViewDismissed:
            reduce { $0.webViewURL = nil }
        }
    }

    private func fetchList(country: String? = nil, category: String? = nil) async {
        reduce { $0.isLoading = true }
        do {
            let result = try await activityClient.fetchList(country, category, nil, nil)
            print("[Activity] activities count: \(result.data.count)")
            reduce { $0.activities = result.data }
        } catch {
            print("[Activity] fetchList failed: \(error.localizedDescription)")
            reduce { $0.activities = [] }
        }
        reduce { $0.isLoading = false }
    }

    private func fetchBanners() async {
        do {
            let result = try await bannerClient.fetchMain()
            reduce { $0.banners = result.data }
        } catch {
            print("[Banner] fetchMain failed: \(error.localizedDescription)")
        }
    }
}

@MainActor
final class ActivitySearchViewModel: BaseViewModel<ActivitySearchFeature.State, ActivitySearchFeature.Intent> {

    private let activityClient: ActivityAPIClient

    init(activityClient: ActivityAPIClient = .live) {
        self.activityClient = activityClient
        super.init(initialState: .init())
    }

    override func send(_ intent: ActivitySearchFeature.Intent) {
        switch intent {
        case .searchSubmitted(let query):
            Task { await search(query: query) }

        case .reset:
            reduce { $0 = .init() }
        }
    }

    private func search(query: String) async {
        guard query.count >= 2 else { return }
        reduce {
            $0.isLoading = true
            $0.hasSearched = true
        }
        do {
            let result = try await activityClient.search(query)
            reduce { $0.results = result.data }
        } catch {
            print("[Activity] search failed: \(error.localizedDescription)")
            reduce { $0.results = [] }
        }
        reduce { $0.isLoading = false }
    }
}
