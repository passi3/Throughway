//
//  SignUpViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

@MainActor
final class SignUpViewModel: BaseViewModel<SignUpFeature.State, SignUpFeature.Intent> {

    // Navigation / Delegation
    var onAuthenticated: ((AuthTokens) -> Void)?
    var onDismiss: (() -> Void)?

    // MARK: - Validation

    /// 닉네임: - . , ? * @ + ^ $ { } ( ) | [ ] \ 포함 불가
    var isNicknameValid: Bool {
        guard !state.nickname.isEmpty else { return false }
        let forbidden = CharacterSet(charactersIn: #"-.,?*@+^${}()|[]\\"#)
        return state.nickname.unicodeScalars.allSatisfy { !forbidden.contains($0) }
    }

    /// 이메일: user@example.com 형식
    var isEmailValid: Bool {
        let pattern = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        return state.email.range(of: pattern, options: .regularExpression) != nil
    }

    /// 비밀번호: 8자 이상, 영문자·숫자·특수문자(@$!%*#?&) 각 1개 이상
    var isPasswordValid: Bool {
        guard state.password.count >= 8 else { return false }
        let hasLetter  = state.password.range(of: "[A-Za-z]", options: .regularExpression) != nil
        let hasNumber  = state.password.range(of: "[0-9]", options: .regularExpression) != nil
        let hasSpecial = state.password.range(of: "[@$!%*#?&]", options: .regularExpression) != nil
        return hasLetter && hasNumber && hasSpecial
    }

    /// 비밀번호 확인: 비어있지 않고 비밀번호와 일치
    var isPasswordConfirmValid: Bool {
        !state.passwordConfirm.isEmpty && state.password == state.passwordConfirm
    }

    var isSignUpEnabled: Bool {
        isNicknameValid &&
        isEmailValid &&
        state.isEmailChecked &&
        isPasswordValid &&
        isPasswordConfirmValid &&
        state.isTermsAgreed
    }

    private let userAPIClient: UserAPIClient

    init(userAPIClient: UserAPIClient) {
        self.userAPIClient = userAPIClient
        super.init(initialState: .init())
    }

    override func send(_ intent: SignUpFeature.Intent) {
        switch intent {
        case .nicknameChanged(let nickname):
            reduce { $0.nickname = nickname }

        case .emailChanged(let email):
            reduce {
                $0.email = email
                $0.isEmailChecked = false
                $0.emailCheckMessage = nil
            }

        case .passwordChanged(let password):
            reduce { $0.password = password }

        case .passwordConfirmChanged(let passwordConfirm):
            reduce { $0.passwordConfirm = passwordConfirm }

        case .passwordVisibilityToggled:
            reduce { $0.isPasswordVisible.toggle() }

        case .passwordConfirmVisibilityToggled:
            reduce { $0.isPasswordConfirmVisible.toggle() }

        case .termsAgreementToggled:
            reduce { $0.isTermsAgreed.toggle() }

        case .emailCheckTapped:
            Task { await _checkEmail() }

        case .signUpTapped:
            Task { await _signUp() }

        case .backTapped, .loginLinkTapped:
            onDismiss?()

        case .reset:
            reduce { $0 = .init() }
        }
    }

    private func _checkEmail() async {
        reduce { $0.isEmailCheckLoading = true }
        defer { reduce { $0.isEmailCheckLoading = false } }
        do {
            try await userAPIClient.validateEmail(state.email)
            reduce {
                $0.isEmailChecked = true
                $0.emailCheckMessage = "사용 가능한 이메일입니다."
            }
        } catch {
            reduce {
                $0.isEmailChecked = false
                $0.emailCheckMessage = error.localizedDescription
            }
        }
    }

    private func _signUp() async {
        reduce { $0.isLoading = true }
        defer { reduce { $0.isLoading = false } }
        let request = SignUpRequestDTO(
            email: state.email,
            password: state.password,
            nick: state.nickname,
            phoneNum: nil,
            introduction: nil,
            deviceToken: nil
        )
        do {
            let response = try await userAPIClient.join(request)
            AppSession.userId = response.userId
            onAuthenticated?(response.tokens)
        } catch {
            // TODO: 에러 처리
        }
    }
}
