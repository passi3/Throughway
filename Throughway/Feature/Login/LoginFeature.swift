//
//  LoginFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum LoginFeature {
    struct State: BaseState {
        var email: String = ""
        var password: String = ""
        var isPasswordVisible: Bool = false
        var isLoading: Bool = false
    }

    enum Intent: BaseIntent {
        case emailChanged(String)
        case passwordChanged(String)
        case passwordVisibilityToggled
        case loginButtonTapped
        case forgotPasswordTapped
        case signUpTapped
        case kakaoLoginTapped
        case appleLoginTapped
        case reset
    }
}
