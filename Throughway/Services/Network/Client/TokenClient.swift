//
//  TokenClient.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation
import Security

struct AuthTokens: Equatable, Sendable {
    let accessToken: String
    let refreshToken: String
}

struct TokenClient {
    var save: @Sendable (AuthTokens) async throws -> Void
    var loadAccessToken: @Sendable () async -> String?
    var loadRefreshToken: @Sendable () async -> String?
    var loadSession: @Sendable () async -> AuthTokens?
    var clear: @Sendable () async -> Void
    var clearAccessToken: @Sendable () async -> Void
    var clearRefreshToken: @Sendable () async -> Void
    var clearRefreshTokenSync: @Sendable () -> Void
}

extension TokenClient {
    static let live: TokenClient = {
        let store = KeychainTokenStore()

        return Self(
            save: { tokens in
                try await store.save(tokens.accessToken, for: .accessToken)
                try await store.save(tokens.refreshToken, for: .refreshToken)
            },
            loadAccessToken: {
                await store.load(.accessToken)
            },
            loadRefreshToken: {
                await store.load(.refreshToken)
            },
            loadSession: {
                let accessToken = await store.load(.accessToken)
                let refreshToken = await store.load(.refreshToken)

                guard let accessToken, let refreshToken else {
                    if accessToken != nil || refreshToken != nil {
                        await store.clearAll()
                    }
                    return nil
                }

                return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
            },
            clear: {
                await store.clearAll()
            },
            clearAccessToken: {
                await store.clear(.accessToken)
            },
            clearRefreshToken: {
                await store.clear(.refreshToken)
            },
            clearRefreshTokenSync: {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: "Throughway.Auth",
                    kSecAttrAccount as String: "refreshToken"
                ]
                SecItemDelete(query as CFDictionary)
            }
        )
    }()
}

// MARK: - Keychain

private actor KeychainTokenStore {
    private enum Constants {
        static let service = "Throughway.Auth"
    }

    enum Item: String, CaseIterable {
        case accessToken
        case refreshToken
    }

    func save(_ value: String, for item: Item) throws {
        let data = Data(value.utf8)
        let query = baseQuery(for: item)

        SecItemDelete(query as CFDictionary)

        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandled(status)
        }
    }

    func load(_ item: Item) -> String? {
        var query = baseQuery(for: item)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var itemRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &itemRef)

        guard status != errSecItemNotFound else { return nil }
        guard status == errSecSuccess,
              let data = itemRef as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    func clear(_ item: Item) {
        SecItemDelete(baseQuery(for: item) as CFDictionary)
    }

    func clearAll() {
        Item.allCases.forEach { clear($0) }
    }

    private func baseQuery(for item: Item) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Constants.service,
            kSecAttrAccount as String: item.rawValue
        ]
    }
}

private enum KeychainError: Error {
    case unhandled(OSStatus)
}
