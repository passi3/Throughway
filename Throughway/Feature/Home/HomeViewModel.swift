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

    private let defaults = UserDefaults.standard
    private func likeKey(_ postId: String) -> String { "post_like_\(postId)" }

    private let activityClient: ActivityAPIClient
    private let postClient: PostAPIClient
    private let userClient: UserAPIClient
    private let locationManager = CLLocationManager()
    private var userLocation: CLLocation?
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
            reduce { $0.distanceKm = distanceKm }
            scheduleFetchPosts()

        case .likeTapped(let post):
            Task { await toggleLike(for: post) }
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
        if let cached = UserDefaults.standard.string(forKey: "myUserId"), !cached.isEmpty {
            reduce { $0.myUserId = cached }
            return
        }
        do {
            let profile = try await userClient.fetchMyProfile()
            UserDefaults.standard.set(profile.userId, forKey: "myUserId")
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
        guard defaults.object(forKey: likeKey(post.postId)) != nil else { return post.isLike }
        return defaults.bool(forKey: likeKey(post.postId))
    }

    func likeCount(for post: PostDTO) -> Int {
        state.likeCountOverrides[post.postId] ?? post.likeCount
    }

    private func toggleLike(for post: PostDTO) async {
        let current = isLiked(post)
        let newStatus = !current
        let currentCount = likeCount(for: post)

        // Optimistic update
        defaults.set(newStatus, forKey: likeKey(post.postId))
        reduce { $0.likeCountOverrides[post.postId] = newStatus ? currentCount + 1 : currentCount - 1 }

        do {
            _ = try await postClient.toggleLike(post.postId, newStatus)
        } catch {
            print("[Home] toggleLike failed: \(error.localizedDescription)")
            // Revert
            defaults.set(current, forKey: likeKey(post.postId))
            reduce { $0.likeCountOverrides[post.postId] = currentCount }
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
        let distanceInMeters = Int(state.distanceKm * 1_000)
        print("[Home] fetchByGeolocation lat=\(lat) lon=\(lon) distance=\(distanceInMeters)m")
        fetchPostsTask = Task {
            do {
                let result = try await postClient.fetchByGeolocation(lat, lon, distanceInMeters)
                if !Task.isCancelled {
                    print("[Home] geoPosts count: \(result.data.count)")
                    reduce { $0.geoPosts = result.data }
                }
            } catch {
                print("[Home] fetchByGeolocation failed: \(error.localizedDescription)")
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
