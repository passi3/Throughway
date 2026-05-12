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
    private var keepObserver: NSObjectProtocol?

    init(activityClient: ActivityAPIClient = .live, bannerClient: BannerAPIClient = .live) {
        self.activityClient = activityClient
        self.bannerClient = bannerClient
        super.init(initialState: .init())
        observeKeepChanges()
    }

    deinit {
        if let keepObserver { NotificationCenter.default.removeObserver(keepObserver) }
    }

    private nonisolated func observeKeepChanges() {
        let observer = NotificationCenter.default.addObserver(
            forName: .activityKeepDidChange, object: nil, queue: .main
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let activityId = info["activityId"] as? String,
                  let isKeep = info["isKeep"] as? Bool,
                  let keepCount = info["keepCount"] as? Int else { return }
            Task { @MainActor in
                self.reduce { $0.keepOverrides[activityId] = (isKeep, keepCount) }
            }
        }
        Task { @MainActor in self.keepObserver = observer }
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

        case .keepToggled(let activityId):
            Task { await toggleKeep(activityId: activityId) }
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

    private func toggleKeep(activityId: String) async {
        guard let activity = state.activities.first(where: { $0.activityId == activityId }) else { return }
        let currentIsKeep = state.keepOverrides[activityId]?.isKeep ?? activity.isKeep
        let currentCount = state.keepOverrides[activityId]?.keepCount ?? activity.keepCount
        let newIsKeep = !currentIsKeep
        let newCount = max(0, currentCount + (newIsKeep ? 1 : -1))
        reduce { $0.keepOverrides[activityId] = (newIsKeep, newCount) }
        do {
            let response = try await activityClient.toggleKeep(activityId, newIsKeep)
            reduce { $0.keepOverrides[activityId] = (response.keepStatus, newCount) }
            NotificationCenter.default.post(
                name: .activityKeepDidChange,
                object: nil,
                userInfo: ["activityId": activityId, "isKeep": response.keepStatus, "keepCount": newCount]
            )
        } catch {
            reduce { $0.keepOverrides[activityId] = nil }
            print("[Activity] toggleKeep failed: \(error.localizedDescription)")
        }
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
    private let bannerClient: BannerAPIClient
    private var keepObserver: NSObjectProtocol?

    init(activityClient: ActivityAPIClient = .live, bannerClient: BannerAPIClient = .live) {
        self.activityClient = activityClient
        self.bannerClient = bannerClient
        super.init(initialState: .init())
        observeKeepChanges()
    }

    deinit {
        if let keepObserver { NotificationCenter.default.removeObserver(keepObserver) }
    }

    override func send(_ intent: ActivitySearchFeature.Intent) {
        switch intent {
        case .onAppear:
            Task { await fetchBanners() }

        case .searchSubmitted(let query):
            Task { await search(query: query) }

        case .reset:
            reduce { $0 = .init() }

        case .keepToggled(let activityId):
            Task { await toggleKeep(activityId: activityId) }

        case .keepUpdated(let activityId, let isKeep, let keepCount):
            reduce { $0.keepOverrides[activityId] = (isKeep, keepCount) }

        case .bannerTapped(let banner):
            guard banner.payload.type == "WEBVIEW",
                  let url = URL(string: APIConstants.baseURL + banner.payload.value) else { return }
            reduce { $0.webViewURL = url }

        case .webViewDismissed:
            reduce { $0.webViewURL = nil }
        }
    }

    private func fetchBanners() async {
        do {
            let result = try await bannerClient.fetchMain()
            reduce { $0.banners = result.data }
        } catch {
            print("[Banner] fetchMain failed: \(error.localizedDescription)")
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

    private func toggleKeep(activityId: String) async {
        guard let activity = state.results.first(where: { $0.activityId == activityId }) else { return }
        let currentIsKeep = state.keepOverrides[activityId]?.isKeep ?? activity.isKeep
        let currentCount = state.keepOverrides[activityId]?.keepCount ?? activity.keepCount
        let newIsKeep = !currentIsKeep
        let newCount = max(0, currentCount + (newIsKeep ? 1 : -1))
        reduce { $0.keepOverrides[activityId] = (newIsKeep, newCount) }
        do {
            let response = try await activityClient.toggleKeep(activityId, newIsKeep)
            reduce { $0.keepOverrides[activityId] = (response.keepStatus, newCount) }
            NotificationCenter.default.post(
                name: .activityKeepDidChange,
                object: nil,
                userInfo: ["activityId": activityId, "isKeep": response.keepStatus, "keepCount": newCount]
            )
        } catch {
            reduce { $0.keepOverrides[activityId] = nil }
            print("[Activity] toggleKeep failed: \(error.localizedDescription)")
        }
    }

    private nonisolated func observeKeepChanges() {
        let observer = NotificationCenter.default.addObserver(
            forName: .activityKeepDidChange, object: nil, queue: .main
        ) { [weak self] notification in
            guard let self,
                  let info = notification.userInfo,
                  let activityId = info["activityId"] as? String,
                  let isKeep = info["isKeep"] as? Bool,
                  let keepCount = info["keepCount"] as? Int else { return }
            Task { @MainActor in
                self.reduce { $0.keepOverrides[activityId] = (isKeep, keepCount) }
            }
        }
        Task { @MainActor in self.keepObserver = observer }
    }
}
