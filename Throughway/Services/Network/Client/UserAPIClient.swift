//
//  UserAPIClient.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation

// MARK: - Client 정의

struct UserAPIClient {
    // 인증 불필요
    var join:          @Sendable (SignUpRequestDTO) async throws -> AuthResponseDTO
    var validateEmail: @Sendable (String) async throws -> Void
    var login:         @Sendable (LoginRequestDTO) async throws -> AuthResponseDTO
    var kakaoLogin:    @Sendable (String) async throws -> AuthResponseDTO
    var appleLogin:    @Sendable (String) async throws -> AuthResponseDTO
    var refreshToken:  @Sendable (String) async throws -> RefreshTokenResponseDTO

    // 인증 필요
    var logout:             @Sendable () async throws -> Void
    var updateDeviceToken:  @Sendable (String) async throws -> Void
    var fetchMyProfile:     @Sendable () async throws -> MyProfileResponseDTO
    var updateMyProfile:    @Sendable (UpdateProfileRequestDTO) async throws -> MyProfileResponseDTO
    var uploadProfileImage: @Sendable (Data) async throws -> ProfileImageResponseDTO
    var searchUser:         @Sendable (String) async throws -> UserSearchResponseDTO
}

// MARK: - Live

extension UserAPIClient {
    static let live: UserAPIClient = {
        let network = SharedNetwork.manager

        return Self(
            join: { dto in
                try await network.request(UserRouter.join(dto))
            },
            validateEmail: { email in
                try await network.request(UserRouter.validateEmail(.init(email: email)))
            },
            login: { dto in
                try await network.request(UserRouter.login(dto))
            },
            kakaoLogin: { token in
                try await network.request(UserRouter.kakaoLogin(.init(oauthToken: token)))
            },
            appleLogin: { token in
                try await network.request(UserRouter.appleLogin(.init(idToken: token)))
            },
            refreshToken: { refreshToken in
                try await network.request(UserRouter.refreshToken(.init(refreshToken: refreshToken)))
            },
            logout: {
                try await network.request(UserRouter.logout)
            },
            updateDeviceToken: { token in
                try await network.request(UserRouter.updateDeviceToken(.init(deviceToken: token)))
            },
            fetchMyProfile: {
                try await network.request(UserRouter.fetchMyProfile)
            },
            updateMyProfile: { dto in
                try await network.request(UserRouter.updateMyProfile(dto))
            },
            uploadProfileImage: { data in
                try await network.request(UserRouter.uploadProfileImage(data))
            },
            searchUser: { query in
                try await network.request(UserRouter.searchUser(query: query))
            }
        )
    }()
}
