//
//  UserRouter.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//


import Foundation
import Alamofire

enum UserRouter: TargetType {
    // 인증 불필요
    case validateEmail(EmailCheckRequestDTO)
    case join(SignUpRequestDTO)
    case login(LoginRequestDTO)
    case kakaoLogin(KakaoLoginRequestDTO)
    case appleLogin(AppleLoginRequestDTO)

    // 인증 필요
    case logout
    case refreshToken(RefreshTokenRequestDTO)
    case updateDeviceToken(DeviceTokenRequestDTO)
    case fetchMyProfile
    case updateMyProfile(UpdateProfileRequestDTO)
    case uploadProfileImage(Data)
    case searchUser(query: String)
}

// MARK: - TargetType 구현

extension UserRouter {

    var path: String {
        switch self {
        case .validateEmail:      return "/v1/users/validation/email"
        case .join:               return "/v1/users/join"
        case .login:              return "/v1/users/login"
        case .kakaoLogin:         return "/v1/users/login/kakao"
        case .appleLogin:         return "/v1/users/login/apple"
        case .logout:             return "/v1/users/logout"
        case .refreshToken:       return "/v1/auth/refresh"
        case .updateDeviceToken:  return "/v1/users/deviceToken"
        case .fetchMyProfile:     return "/v1/users/me/profile"
        case .updateMyProfile:    return "/v1/users/me/profile"
        case .uploadProfileImage: return "/v1/users/profile/image"
        case .searchUser:         return "/v1/users/search"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .join, .validateEmail,
                .login, .kakaoLogin, .appleLogin,
             .logout, .uploadProfileImage:
            return .post
        case .updateDeviceToken, .updateMyProfile:
            return .put
        case .fetchMyProfile, .searchUser, .refreshToken:
            return .get
        }
    }

    var headers: [String: String] {
        defaultHeaders
    }

    var body: RequestBody {
        switch self {
        case .join(let dto):              return .json(dto)
        case .validateEmail(let dto):     return .json(dto)
        case .login(let dto):             return .json(dto)
        case .kakaoLogin(let dto):        return .json(dto)
        case .appleLogin(let dto):        return .json(dto)
        case .refreshToken(let dto):      return .json(dto)
        case .updateDeviceToken(let dto): return .json(dto)
        case .updateMyProfile(let dto):   return .json(dto)
        case .uploadProfileImage(let data):
            let part = MultipartBody.Part(
                name: "profile",
                data: data,
                fileName: "profile.jpg",
                mimeType: "image/jpeg"
            )
            return .multipart(MultipartBody(parts: [part]))
        case .logout, .fetchMyProfile, .searchUser:
            return .none
        }
    }

    var requiresAuthorization: Bool {
        switch self {
        case .logout, .refreshToken, .updateDeviceToken, .fetchMyProfile, .updateMyProfile, .uploadProfileImage, .searchUser:
            return true
        case .validateEmail, .join, .login, .kakaoLogin, .appleLogin:
            return false
        }
    }

    var queryItems: [URLQueryItem]? {
        switch self {
        case .searchUser(let query):
            return [URLQueryItem(name: "nick", value: query)]
        default:
            return nil
        }
    }
}
