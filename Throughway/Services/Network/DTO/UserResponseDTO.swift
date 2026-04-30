//
//  UserResponseDTO.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation

// 회원가입 / 로그인 공통 응답
nonisolated struct AuthResponseDTO: Decodable {
    let userId: String
    let email: String
    let nick: String
    let accessToken: String
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email, nick, accessToken, refreshToken
    }
}

extension AuthResponseDTO {
    var tokens: AuthTokens {
        AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}

nonisolated struct RefreshTokenResponseDTO: Decodable {
    let accessToken: String
    let refreshToken: String
}

extension RefreshTokenResponseDTO {
    var tokens: AuthTokens {
        AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
}

// 내 프로필 조회
nonisolated struct MyProfileResponseDTO: Decodable {
    let userId: String
    let email: String
    let nick: String
    let phoneNum: String?
    let introduction: String?
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email, nick, phoneNum, introduction, profileImage
    }
}

// 유저 검색
nonisolated struct UserSearchResponseDTO: Decodable {
    let data: [UserSummaryDTO]
}

nonisolated struct UserSummaryDTO: Decodable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick, profileImage
    }
}

// 프로필 이미지 업로드
nonisolated struct ProfileImageResponseDTO: Decodable {
    let profileImage: String
}
