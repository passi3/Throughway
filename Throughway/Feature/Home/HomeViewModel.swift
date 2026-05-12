//
//  HomeViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation
import CoreLocation

@MainActor
final class HomeViewModel: BaseViewModel<HomeFeature.State, HomeFeature.Intent> {

    private let activityClient: ActivityAPIClient
    private let postClient: PostAPIClient
    private let userClient: UserAPIClient
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
    var currentLatitude: Double? { userLocation?.coordinate.latitude }
    var currentLongitude: Double? { userLocation?.coordinate.longitude }
    private var fetchPostsTask: Task<Void, Never>?
    private var isAwaitingLocationForPosts = false

    init(
        activityClient: ActivityAPIClient = .live,
        postClient: PostAPIClient = .live,
        userClient: UserAPIClient = .live
    ) {
        self.activityClient = activityClient
        self.postClient = postClient
        self.userClient = userClient
        super.init(initialState: .init())
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    override func send(_ intent: HomeFeature.Intent) {
        switch intent {
        case .start:
            start()

        case .fetchNewActivities(let country, let category):
            Task { await fetchNewActivities(country: country, category: category) }

        case .distanceChanged(let distanceKm):
            print("[Home] distanceChanged: \(distanceKm)km")
            reduce { $0.distanceKm = distanceKm }
            if state.isDistanceEnabled { scheduleFetchPosts() }

        case .distanceToggled:
            reduce { $0.isDistanceEnabled.toggle() }
            print("[Home] distanceEnabled: \(state.isDistanceEnabled)")
            scheduleFetchPosts()

        case .likeTapped(let post):
            Task { await toggleLike(for: post) }

        case .loadMorePosts:
            guard !state.isLoadingMorePosts, state.nextCursor != nil else { return }
            Task { await loadMorePosts() }

        case .refreshPosts:
            reduce { $0.geoPosts = []; $0.nextCursor = nil }
            scheduleFetchPosts()

        case .sortChanged(let order):
            reduce { $0.sortOrder = order; $0.geoPosts = []; $0.nextCursor = nil }
            scheduleFetchPosts()

        case .deletePost(let postId):
            Task { await _deletePost(postId: postId) }
        }
    }

    private func start() {
        Task { await loadMyUserId() }
        let status = locationManager.authorizationStatus
        print("[Home] location authorization status: \(status.logDescription)")
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            requestCurrentLocation()
        case .restricted, .denied:
            print("[Home] location access is unavailable")
        @unknown default:
            print("[Home] location authorization status is unknown")
        }
    }

    private func loadMyUserId() async {
        guard state.myUserId.isEmpty else { return }
        if !AppSession.userId.isEmpty {
            reduce { $0.myUserId = AppSession.userId }
            return
        }
        do {
            let profile = try await userClient.fetchMyProfile()
            AppSession.userId = profile.userId
            reduce { $0.myUserId = profile.userId }
        } catch {
            print("[Home] loadMyUserId error:", error)
        }
    }

    private func fetchNewActivities(country: String?, category: String?) async {
        reduce { $0.isLoadingNewActivities = true }
        do {
            let result = try await activityClient.fetchNew(country, category)
            print("[Home] newActivities count: \(result.data.count)")
            reduce { $0.newActivities = result.data }
        } catch {
            print("[Home] fetchNewActivities failed: \(error.localizedDescription)")
            reduce { $0.newActivities = [] }
        }
        reduce { $0.isLoadingNewActivities = false }
    }

    func isLiked(_ post: PostDTO) -> Bool {
        state.likeOverrides[post.postId] ?? post.isLike
    }

    func likeCount(for post: PostDTO) -> Int {
        state.likeCountOverrides[post.postId] ?? post.likeCount
    }

    func commentCount(for post: PostDTO) -> Int {
        state.commentCountOverrides[post.postId] ?? post.displayCommentCount
    }

    func incrementCommentCount(for postId: String) {
        let currentCount = state.commentCountOverrides[postId]
            ?? state.geoPosts.first(where: { $0.postId == postId })?.displayCommentCount
            ?? 0
        reduce { $0.commentCountOverrides[postId] = currentCount + 1 }
    }

    func decrementCommentCount(for postId: String) {
        let currentCount = state.commentCountOverrides[postId]
            ?? state.geoPosts.first(where: { $0.postId == postId })?.displayCommentCount
            ?? 0
        reduce { $0.commentCountOverrides[postId] = max(0, currentCount - 1) }
    }

    private func toggleLike(for post: PostDTO) async {
        let current = isLiked(post)
        let newStatus = !current
        let currentCount = likeCount(for: post)

        // Optimistic update
        reduce {
            $0.likeOverrides[post.postId] = newStatus
            $0.likeCountOverrides[post.postId] = newStatus ? currentCount + 1 : currentCount - 1
        }

        do {
            _ = try await postClient.toggleLike(post.postId, newStatus)
            InteractionCache.shared.setLiked(post.postId, isLiked: newStatus)
        } catch {
            print("[Home] toggleLike failed: \(error.localizedDescription)")
            // Revert
            reduce {
                $0.likeOverrides[post.postId] = current
                $0.likeCountOverrides[post.postId] = currentCount
            }
        }
    }

    private func scheduleFetchPosts() {
        guard let location = userLocation else {
            print("[Home] scheduleFetchPosts deferred: no user location")
            isAwaitingLocationForPosts = true
            requestCurrentLocation()
            return
        }
        isAwaitingLocationForPosts = false
        fetchPostsTask?.cancel()
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let maxDistance: Int? = state.isDistanceEnabled ? Int(state.distanceKm * 1_000) : nil
        let sortOrder = state.sortOrder
        print("[Home] fetchByGeolocation lat=\(lat) lon=\(lon) maxDistance=\(maxDistance.map { "\($0)m" } ?? "전체") orderBy=\(sortOrder)")
        fetchPostsTask = Task {
            do {
                let result = try await postClient.fetchByGeolocation(lat, lon, maxDistance, nil, nil, sortOrder)
                if !Task.isCancelled {
                    print("[Home] geoPosts count: \(result.data.count)")
                    result.data.forEach { InteractionCache.shared.setLiked($0.postId, isLiked: $0.isLike) }
                    reduce {
                        $0.commentCountOverrides = [:]
                        $0.geoPosts = result.data
                        $0.nextCursor = normalizedNextCursor(result.nextCursor)
                    }
                    await enrichCommentCounts(for: result.data)
                }
            } catch {
                print("[Home] fetchByGeolocation failed: \(error)")
            }
        }
    }

    private func loadMorePosts() async {
        guard let location = userLocation, let cursor = state.nextCursor else { return }
        reduce { $0.isLoadingMorePosts = true }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let maxDistance: Int? = state.isDistanceEnabled ? Int(state.distanceKm * 1_000) : nil
        do {
            let result = try await postClient.fetchByGeolocation(lat, lon, maxDistance, cursor, nil, state.sortOrder)
            print("[Home] loadMore geoPosts count: \(result.data.count)")
            let existingPostIds = Set(state.geoPosts.map(\.postId))
            let newPosts = result.data.filter { !existingPostIds.contains($0.postId) }
            newPosts.forEach { InteractionCache.shared.setLiked($0.postId, isLiked: $0.isLike) }
            reduce {
                $0.geoPosts.append(contentsOf: newPosts)
                $0.nextCursor = normalizedNextCursor(result.nextCursor)
            }
            await enrichCommentCounts(for: newPosts)
        } catch {
            print("[Home] loadMorePosts failed: \(error.localizedDescription)")
        }
        reduce { $0.isLoadingMorePosts = false }
    }

    private func _deletePost(postId: String) async {
        do {
            try await postClient.deletePost(postId)
            reduce {
                $0.geoPosts.removeAll { $0.postId == postId }
                $0.commentCountOverrides.removeValue(forKey: postId)
                $0.likeOverrides.removeValue(forKey: postId)
                $0.likeCountOverrides.removeValue(forKey: postId)
            }
            scheduleFetchPosts()
        } catch {
            print("[Home] deletePost failed: \(error)")
        }
    }

    private func normalizedNextCursor(_ cursor: String?) -> String? {
        guard let cursor else { return nil }
        let trimmed = cursor.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "0" else { return nil }
        return trimmed
    }

    private func enrichCommentCounts(for posts: [PostDTO]) async {
        await withTaskGroup(of: (String, Int)?.self) { group in
            for post in posts {
                group.addTask { [postClient] in
                    do {
                        let detail = try await postClient.fetchDetail(post.postId)
                        let count = detail.comments.reduce(0) { $0 + 1 + $1.replies.count }
                        return (post.postId, count)
                    } catch {
                        print("[Home] fetchDetail failed for \(post.postId): \(error.localizedDescription)")
                        return nil
                    }
                }
            }

            for await result in group {
                guard !Task.isCancelled, let (postId, count) = result else { continue }
                reduce { $0.commentCountOverrides[postId] = count }
            }
        }
    }

    private func requestCurrentLocation() {
        print("[Home] requesting current location")
        locationManager.requestLocation()
    }
}

extension HomeViewModel: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            print("[Home] location authorization changed: \(status.logDescription)")
            guard let self else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.requestCurrentLocation()
            case .restricted, .denied:
                print("[Home] location access denied or restricted")
            case .notDetermined:
                break
            @unknown default:
                print("[Home] location authorization changed to unknown status")
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            let isFirst = self.userLocation == nil
            self.userLocation = loc
            print("[Home] didUpdateLocations lat=\(loc.coordinate.latitude) lon=\(loc.coordinate.longitude)")
            if isFirst || self.isAwaitingLocationForPosts {
                self.scheduleFetchPosts()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[Home] location update failed: \(error.localizedDescription)")
    }
}

private extension CLAuthorizationStatus {
    var logDescription: String {
        switch self {
        case .notDetermined:      return "notDetermined"
        case .restricted:         return "restricted"
        case .denied:             return "denied"
        case .authorizedAlways:   return "authorizedAlways"
        case .authorizedWhenInUse:return "authorizedWhenInUse"
        @unknown default:         return "unknown"
        }
    }
}
