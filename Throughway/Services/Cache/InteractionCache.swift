//
//  InteractionCache.swift
//  Throughway
//
//  Created by passi on 5/11/26.
//

import Foundation

/// 사용자의 좋아요/구매 상태를 로컬에 영속 저장하는 캐시.
/// UserDefaults 기반이므로 앱 재실행 후에도 유지된다.
final class InteractionCache {
    static let shared = InteractionCache()
    private init() {}

    private let defaults = UserDefaults.standard

    private enum Key {
        static let likedPostIds = "cache.likedPostIds"
        static let purchasedActivityIds = "cache.purchasedActivityIds"
    }

    // MARK: - Likes

    func isLiked(_ postId: String) -> Bool {
        likedPostIds.contains(postId)
    }

    func setLiked(_ postId: String, isLiked: Bool) {
        var ids = likedPostIds
        if isLiked { ids.insert(postId) } else { ids.remove(postId) }
        defaults.set(Array(ids), forKey: Key.likedPostIds)
    }

    private var likedPostIds: Set<String> {
        Set(defaults.stringArray(forKey: Key.likedPostIds) ?? [])
    }

    // MARK: - Purchases

    func isPurchased(_ activityId: String) -> Bool {
        purchasedActivityIds.contains(activityId)
    }

    func markPurchased(_ activityId: String) {
        var ids = purchasedActivityIds
        ids.insert(activityId)
        defaults.set(Array(ids), forKey: Key.purchasedActivityIds)
    }

    private var purchasedActivityIds: Set<String> {
        Set(defaults.stringArray(forKey: Key.purchasedActivityIds) ?? [])
    }

    // MARK: - Clear on logout

    func clearAll() {
        defaults.removeObject(forKey: Key.likedPostIds)
        defaults.removeObject(forKey: Key.purchasedActivityIds)
    }
}
