//
//  SignUpFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum SignUpFeature {
    struct State: BaseState {
        var nickname: String = ""
        var email: String = ""
        var password: String = ""
        var passwordConfirm: String = ""
        var isPasswordVisible: Bool = false
        var isPasswordConfirmVisible: Bool = false
        var isTermsAgreed: Bool = false
        var isLoading: Bool = false
        var isEmailChecked: Bool = false
        var isEmailCheckLoading: Bool = false
        var emailCheckMessage: String?
    }

    enum Intent: BaseIntent {
        case nicknameChanged(String)
        case emailChanged(String)
        case passwordChanged(String)
        case passwordConfirmChanged(String)
        case passwordVisibilityToggled
        case passwordConfirmVisibilityToggled
        case termsAgreementToggled
        case emailCheckTapped
        case signUpTapped
        case backTapped
        case loginLinkTapped
        case reset
    }
}
