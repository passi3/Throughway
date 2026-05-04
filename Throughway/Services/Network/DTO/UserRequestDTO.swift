//
//  UserRequestDTO.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation

struct SignUpRequestDTO: Encodable {
    let email: String
    let password: String
    let nick: String
    let phoneNum: String?
    let introduction: String?
    let deviceToken: String?
}

struct EmailCheckRequestDTO: Encodable {
    let email: String
}

struct LoginRequestDTO: Encodable {
    let email: String
    let password: String
}

struct KakaoLoginRequestDTO: Encodable {
    let oauthToken: String
}

struct AppleLoginRequestDTO: Encodable {
    let idToken: String
}

struct RefreshTokenRequestDTO: Encodable {
    let refreshToken: String
}

struct DeviceTokenRequestDTO: Encodable {
    let deviceToken: String
}

struct UpdateProfileRequestDTO: Encodable {
    let nick: String?
    let phoneNum: String?
    let introduction: String?
    let profileImage: String?
}
