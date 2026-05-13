//
//  AuthView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            switch viewModel.state.phase {
            case .loading:
                ProgressView("세션 확인 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.bgPrimary)

            case .unauthenticated:
                NavigationStack(path: navigationPathBinding) {
                    LoginView(viewModel: viewModel.loginViewModel)
                        .navigationBarHidden(true)
                        .navigationDestination(for: AuthRoute.self) { route in
                            switch route {
                            case .signUp:
                                if let signUpVM = viewModel.signUpViewModel {
                                    SignUpView(viewModel: signUpVM)
                                        .navigationBarHidden(true)
                                }
                            }
                        }
                }

            case .authenticated:
                MainView(onLogout: { viewModel.send(.logoutTapped) })
            }
        }
        .task {
            viewModel.send(.start)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                viewModel.send(.handleForeground)
            }
        }
    }

    private var navigationPathBinding: Binding<[AuthRoute]> {
        Binding(
            get: { viewModel.state.navigationPath },
            set: { viewModel.send(.navigationPathChanged($0)) }
        )
    }
}
