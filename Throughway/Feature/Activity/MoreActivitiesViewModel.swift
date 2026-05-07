//
//  MoreActivitiesViewModel.swift
//  Throughway
//
//  Created by passi on 5/6/26.
//

import Foundation

@MainActor
final class MoreActivitiesViewModel: BaseViewModel<MoreActivitiesFeature.State, MoreActivitiesFeature.Intent> {

    private let activityClient: ActivityAPIClient
    private let bannerClient: BannerAPIClient
    private var keepObserver: NSObjectProtocol?

    init(
        activityClient: ActivityAPIClient = .live,
        bannerClient: BannerAPIClient = .live
    ) {
        self.activityClient = activityClient
        self.bannerClient = bannerClient
        super.init(initialState: .init())
        observeKeepChanges()
    }

    deinit {
        if let keepObserver { NotificationCenter.default.removeObserver(keepObserver) }
    }

    override func send(_ intent: MoreActivitiesFeature.Intent) {
        switch intent {
        case .onAppear:
            Task {
                async let a: () = _fetchActivities(category: nil, into: \.recommended)
                async let b: () = _fetchActivities(category: "익사이팅", into: \.exciting)
                async let c: () = _fetchBanners()
                _ = await (a, b, c)
            }

        case .bannerTapped(let banner):
            guard banner.payload.type == "WEBVIEW",
                  let url = URL(string: APIConstants.baseURL + banner.payload.value) else { return }
            reduce { $0.webViewURL = url }

        case .webViewDismissed:
            reduce { $0.webViewURL = nil }

        case .keepToggled(let activityId):
            Task { await _toggleKeep(activityId: activityId) }
        }
    }

    func displayed(_ activity: ActivitySummaryDTO) -> ActivitySummaryDTO {
        guard let o = state.keepOverrides[activity.activityId] else { return activity }
        return ActivitySummaryDTO(activity, isKeep: o.isKeep, keepCount: o.keepCount)
    }

    @MainActor
    private func _fetchActivities(
        category: String?,
        into keyPath: WritableKeyPath<MoreActivitiesFeature.State, [ActivitySummaryDTO]>
    ) async {
        reduce { $0.isLoading = true }
        do {
            let result = try await activityClient.fetchList(nil, category, nil, nil)
            reduce { $0[keyPath: keyPath] = result.data }
        } catch {
            print("[MoreActivities] fetch(\(category ?? "all")) failed:", error.localizedDescription)
            reduce { $0[keyPath: keyPath] = [] }
        }
        reduce { $0.isLoading = false }
    }

    @MainActor
    private func _fetchBanners() async {
        do {
            let result = try await bannerClient.fetchMain()
            reduce { $0.banners = result.data }
        } catch {
            print("[MoreActivities] fetchBanners failed:", error.localizedDescription)
        }
    }

    @MainActor
    private func _toggleKeep(activityId: String) async {
        let all = state.recommended + state.exciting
        guard let activity = all.first(where: { $0.activityId == activityId }) else { return }
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
            print("[MoreActivities] toggleKeep failed:", error.localizedDescription)
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
