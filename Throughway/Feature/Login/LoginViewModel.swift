//
//  LoginViewModel.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation

@MainActor
final class LoginViewModel: BaseViewModel<LoginFeature.State, LoginFeature.Intent> {

    // Navigation / Delegation
    var onAuthenticated: ((AuthTokens) -> Void)?
    var onSignUpTapped: (() -> Void)?

    private let userAPIClient: UserAPIClient

    init(userAPIClient: UserAPIClient) {
        self.userAPIClient = userAPIClient
        super.init(initialState: .init())
    }

    override func send(_ intent: LoginFeature.Intent) {
        switch intent {
        case .emailChanged(let email):
            reduce { $0.email = email }

        case .passwordChanged(let password):
            reduce { $0.password = password }

        case .passwordVisibilityToggled:
            reduce { $0.isPasswordVisible.toggle() }

        case .loginButtonTapped:
            Task { await _login() }

        case .forgotPasswordTapped:
            break

        case .signUpTapped:
            onSignUpTapped?()

        case .kakaoLoginTapped:
            break

        case .appleLoginTapped:
            break

        case .reset:
            reduce { $0 = .init() }
        }
    }

    private func _login() async {
        reduce { $0.isLoading = true }
        defer { reduce { $0.isLoading = false } }

        let request = LoginRequestDTO(email: state.email, password: state.password)
        do {
            let response = try await userAPIClient.login(request)
            AppSession.userId = response.userId
            onAuthenticated?(response.tokens)
        } catch {
            // TODO: 에러 처리
        }
    }
}
