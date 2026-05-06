//
//  UserDefaultsManager.swift
//  Throughway
//
//  Created by passi on 5/5/26.
//

import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults.standard

    private enum Key {
        static let myUserId = "myUserId"
        static func postLike(_ postId: String) -> String { "post_like_\(postId)" }
    }

    private init() {}

    // MARK: - User

    var myUserId: String {
        get { defaults.string(forKey: Key.myUserId) ?? "" }
        set { defaults.set(newValue, forKey: Key.myUserId) }
    }

    // MARK: - Post Like

    func isLiked(postId: String) -> Bool? {
        let key = Key.postLike(postId)
        guard defaults.object(forKey: key) != nil else { return nil }
        return defaults.bool(forKey: key)
    }

    func setLiked(_ isLiked: Bool, postId: String) {
        defaults.set(isLiked, forKey: Key.postLike(postId))
    }

    func removePostLike(postId: String) {
        defaults.removeObject(forKey: Key.postLike(postId))
    }

    // MARK: - Clear

    func clear() {
        defaults.removeObject(forKey: Key.myUserId)
    }
}
