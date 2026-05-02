//
//  LoginView.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel
    @FocusState private var focusedField: LoginField?
    
    enum LoginField {
        case email, password
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 36)

            headerSection

            Spacer().frame(height: 48)

            inputSection

            forgotPasswordButton
                .padding(.top, 12)

            loginButton
                .padding(.top, 30)

            dividerSection
                .padding(.top, 16)

            socialLoginSection
                .padding(.top, 12)

            signUpSection
                .padding(.top, 12)

            Spacer().frame(height: 160)
        }
        .padding(.horizontal, 20)
        .background(Color.gray0)
        
    }
}

private extension LoginView {

    var headerSection: some View {
        VStack(spacing: 8) {
            Text("Throughway")
                .font(.Paperlogy.title1)
                .fontWeight(.bold)
                .foregroundStyle(Color.blackSeafoam)

            Text("여행을 더 특별하게")
                .font(.Pretendard.body3)
                .foregroundStyle(Color.gray60)
        }
        .frame(maxWidth: .infinity)
    }

    var inputSection: some View {
        VStack(spacing: 20) {
            // 이메일
            VStack(alignment: .leading, spacing: 8) {
                Text("이메일")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray90)

                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .foregroundStyle(Color.gray45)
                    TextField("이메일을 입력하세요", text: emailBinding)
                        .font(.Pretendard.body2)
                        .foregroundStyle(Color.gray90)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .password }
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray15, lineWidth: 1)
                }
            }

            // 비밀번호
            VStack(alignment: .leading, spacing: 8) {
                Text("비밀번호")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray90)

                let isVisible = viewModel.state.isPasswordVisible
                HStack(spacing: 10) {
                    Image(systemName: "lock")
                        .foregroundStyle(Color.gray45)

                    Group {
                        if isVisible {
                            TextField("비밀번호를 입력하세요", text: passwordBinding)
                        } else {
                            SecureField("비밀번호를 입력하세요", text: passwordBinding)
                        }
                    }
                    .font(.Pretendard.body2)
                    .foregroundStyle(Color.gray90)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit { viewModel.send(.loginButtonTapped) }

                    Button {
                        viewModel.send(.passwordVisibilityToggled)
                    } label: {
                        Image(systemName: isVisible ? "eye" : "eye.slash")
                            .foregroundStyle(Color.gray45)
                    }
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray15, lineWidth: 1)
                }
            }
        }
    }

    var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button("비밀번호를 잊으셨나요?") {
                viewModel.send(.forgotPasswordTapped)
            }
            .font(.Pretendard.caption1)
            .foregroundStyle(Color.blackSeafoam)
        }
    }

    var loginButton: some View {
        let isLoading = viewModel.state.isLoading
        return Button {
            viewModel.send(.loginButtonTapped)
        } label: {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("로그인")
                        .font(.Pretendard.body1)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.blackSeafoam)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(isLoading)
    }

    var dividerSection: some View {
        HStack(spacing: 12) {
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray15)
            Text("또는")
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray45)
                .fixedSize()
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray15)
        }
    }

    var socialLoginSection: some View {
        VStack(spacing: 12) {
            Button {
                viewModel.send(.kakaoLoginTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .foregroundStyle(Color(red: 0, green: 0, blue: 0, opacity: 0.85))
                    Text("카카오로 계속하기")
                        .font(.Pretendard.body2)
                        .fontWeight(.medium)
                        .foregroundStyle(Color(red: 0, green: 0, blue: 0, opacity: 0.85))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color(red: 254/255, green: 229/255, blue: 0/255))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                viewModel.send(.appleLoginTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "apple.logo")
                        .foregroundStyle(.white)
                    Text("Apple로 계속하기")
                        .font(.Pretendard.body2)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.gray100)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    var signUpSection: some View {
        HStack(spacing: 4) {
            Text("아직 계정이 없으신가요?")
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray60)
            Button("회원가입") {
                viewModel.send(.signUpTapped)
            }
            .font(.Pretendard.caption1)
            .foregroundStyle(Color.blackSeafoam)
        }
    }

    var emailBinding: Binding<String> {
        Binding(
            get: { viewModel.state.email },
            set: { viewModel.send(.emailChanged($0)) }
        )
    }

    var passwordBinding: Binding<String> {
        Binding(
            get: { viewModel.state.password },
            set: { viewModel.send(.passwordChanged($0)) }
        )
    }
}
