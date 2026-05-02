//
//  AuthViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum AuthRoute: Hashable {
    case signUp
}

@MainActor
final class AuthViewModel: BaseViewModel<AuthFeature.State, AuthFeature.Intent> {

    let loginViewModel: LoginViewModel
    private(set) var signUpViewModel: SignUpViewModel?

    private let tokenClient: TokenClient
    private let userAPIClient: UserAPIClient
    private var sessionMonitorTask: Task<Void, Never>?
    /// start()가 완료되기 전에 foreground 이벤트가 오는 것을 방지
    @MainActor private var isStarted = false

    init(
        tokenClient: TokenClient = .live,
        userAPIClient: UserAPIClient = .live
    ) {
        self.tokenClient = tokenClient
        self.userAPIClient = userAPIClient
        self.loginViewModel = LoginViewModel(userAPIClient: userAPIClient)
        super.init(initialState: .init())
        bindLoginCallbacks()
    }

    override func send(_ intent: AuthFeature.Intent) {
        switch intent {
        case .start:
            Task { await start() }

        case .handleForeground:
            Task { await handleForeground() }

        case .logoutTapped:
            Task { await _logout() }

        case .navigateToSignUp:
            navigateToSignUp()

        case .navigationPathChanged(let path):
            reduce { $0.navigationPath = path }

        case .sessionStored(let tokens):
            Task { await storeSession(tokens) }

        case .sessionInvalidated, .resetToUnauthenticated:
            resetToUnauthenticated()

        case .phaseChanged(let phase):
            reduce { $0.phase = phase }
        }
    }

    /// 앱 프로세스 종료 시 호출.
    func handleTermination() {
        // 로그인 유지: 앱 종료 시 Refresh Token 삭제하지 않음
    }

    /// 앱이 suspend → foreground 복귀 시 호출
    func handleForeground() async {
        guard isStarted, state.phase != .loading else { return }
        reduce { $0.phase = .loading }
        await attemptSilentRefresh()
    }

    // MARK: - Private

    private func start() async {
        isStarted = false
        await loadSession()
        startMonitoringSession()
        isStarted = true
    }

    private func bindLoginCallbacks() {
        loginViewModel.onAuthenticated = { [weak self] tokens in
            self?.send(.sessionStored(tokens))
        }
        loginViewModel.onSignUpTapped = { [weak self] in
            self?.send(.navigateToSignUp)
        }
    }

    private func navigateToSignUp() {
        let vm = SignUpViewModel(userAPIClient: userAPIClient)
        vm.onAuthenticated = { [weak self] tokens in
            self?.send(.sessionStored(tokens))
        }
        vm.onDismiss = { [weak self] in
            guard let self else { return }
            var path = self.state.navigationPath
            if !path.isEmpty {
                path.removeLast()
            }
            self.reduce { $0.navigationPath = path }
            self.signUpViewModel = nil
        }
        signUpViewModel = vm
        reduce { $0.navigationPath.append(.signUp) }
    }

    /// 리프레시 토큰으로 새 액세스토큰 발급 시도
    /// - 성공: 키체인 저장 → authenticated
    /// - 리프레시 토큰 없음 / 실패: 토큰 전체 삭제 → unauthenticated
    private func attemptSilentRefresh() async {
        guard let refreshToken = await tokenClient.loadRefreshToken() else {
            reduce { $0.phase = .unauthenticated }
            return
        }
        do {
            let dto = try await userAPIClient.refreshToken(refreshToken)
            try await tokenClient.save(dto.tokens)
            reduce { $0.phase = .authenticated }
        } catch {
            await tokenClient.clear()
            resetToUnauthenticated()
        }
    }

    private func loadSession() async {
        reduce { $0.phase = .loading }
        if await tokenClient.loadAccessToken() != nil {
            // access token 존재 → 낙관적으로 authenticated
            // 만료된 경우 NetworkManager의 AuthInterceptor가 401 시 자동 갱신
            reduce { $0.phase = .authenticated }
        } else {
            await attemptSilentRefresh()
        }
    }

    private func startMonitoringSession() {
        sessionMonitorTask?.cancel()
        sessionMonitorTask = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: Notification.Name("sessionDidInvalidate")) {
                self?.handleSessionInvalidated()
            }
        }
    }

    private func handleSessionInvalidated() {
        resetToUnauthenticated()
    }

    private func storeSession(_ tokens: AuthTokens) async {
        reduce { $0.phase = .loading }
        do {
            try await tokenClient.save(tokens)
            reduce {
                $0.phase = .authenticated
                $0.navigationPath = []
            }
            signUpViewModel = nil
            loginViewModel.send(.reset)
        } catch {
            reduce { $0.phase = .unauthenticated }
        }
    }

    /// 로그아웃: Access Token + Refresh Token 모두 삭제
    private func _logout() async {
        reduce { $0.phase = .loading }
        do { try await userAPIClient.logout() } catch {}
        await tokenClient.clear()
        resetToUnauthenticated()
    }

    private func resetToUnauthenticated() {
        reduce {
            $0.phase = .unauthenticated
            $0.navigationPath = []
        }
        signUpViewModel = nil
        loginViewModel.send(.reset)
    }

    deinit {
        sessionMonitorTask?.cancel()
    }
}
