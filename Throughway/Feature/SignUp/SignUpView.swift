//
//  SignUpView.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import SwiftUI

struct SignUpView: View {
    @ObservedObject var viewModel: SignUpViewModel

    var body: some View {
        VStack(spacing: 0) {
            navigationBar

            ScrollView {
                VStack(spacing: 0) {
                    inputSection
                        .padding(.top, 16)

                    termsRow
                        .padding(.top, 16)

                    signUpButton
                        .padding(.top, 26)

                    loginLinkSection
                        .padding(.top, 20)
                }
                .padding(.horizontal, 20)
            }
        }
        .background(Color.gray0)
        .navigationBarHidden(true)
    }
}

// MARK: - Sections

private extension SignUpView {

    var navigationBar: some View {
        ZStack {
            Text("회원가입")
                .font(.Pretendard.body1)
                .fontWeight(.semibold)
                .foregroundStyle(Color.gray100)

            HStack {
                Button {
                    viewModel.send(.backTapped)
                } label: {
                    AppIcon.back
                        .foregroundStyle(Color.gray100)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 56)
    }

    var inputSection: some View {
        VStack(spacing: 16) {
            inputField(
                label: "닉네임",
                icon: "person",
                placeholder: "닉네임을 입력하세요",
                text: nicknameBinding,
                isValid: viewModel.state.nickname.isEmpty ? nil : viewModel.isNicknameValid
            )

            inputField(
                label: "이메일",
                icon: "envelope",
                placeholder: "이메일을 입력하세요",
                text: emailBinding,
                keyboardType: .emailAddress,
                isValid: viewModel.state.email.isEmpty ? nil : viewModel.isEmailValid,
                trailingButton: {
                    viewModel.send(.emailCheckTapped)
                },
                trailingButtonLabel: "이메일 확인",
                trailingButtonEnabled: viewModel.isEmailValid && !viewModel.state.isEmailCheckLoading,
                trailingButtonLoading: viewModel.state.isEmailCheckLoading,
                statusMessage: viewModel.state.emailCheckMessage
            )

            secureInputField(
                label: "비밀번호",
                placeholder: "비밀번호를 입력하세요",
                text: passwordBinding,
                isVisible: viewModel.state.isPasswordVisible,
                isValid: viewModel.state.password.isEmpty ? nil : viewModel.isPasswordValid,
                hint: "8자 이상, 영문자·숫자·특수문자(@$!%*#?&) 포함",
                onToggleVisibility: { viewModel.send(.passwordVisibilityToggled) }
            )

            secureInputField(
                label: "비밀번호 확인",
                placeholder: "비밀번호를 다시 입력하세요",
                text: passwordConfirmBinding,
                isVisible: viewModel.state.isPasswordConfirmVisible,
                isValid: viewModel.state.passwordConfirm.isEmpty ? nil : viewModel.isPasswordConfirmValid,
                onToggleVisibility: { viewModel.send(.passwordConfirmVisibilityToggled) }
            )
        }
    }

    var termsRow: some View {
        let isAgreed = viewModel.state.isTermsAgreed
        return Button {
            viewModel.send(.termsAgreementToggled)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isAgreed ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isAgreed ? Color.blackSeafoam : Color.gray45)
                    .font(.system(size: 18))

                Text("서비스 이용약관 및 개인정보 처리방침에 동의합니다")
                    .font(.Pretendard.caption1)
                    .foregroundStyle(Color.gray75)
                    .multilineTextAlignment(.leading)

                Spacer()
            }
        }
    }

    var signUpButton: some View {
        let isEnabled = viewModel.isSignUpEnabled
        let isLoading = viewModel.state.isLoading
        return Button {
            viewModel.send(.signUpTapped)
        } label: {
            Group {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("회원가입")
                        .font(.Pretendard.body1)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? Color.blackSeafoam : Color.gray30)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .disabled(!isEnabled || isLoading)
    }

    var loginLinkSection: some View {
        HStack(spacing: 4) {
            Text("이미 계정이 있으신가요?")
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray60)
            Button("로그인") {
                viewModel.send(.loginLinkTapped)
            }
            .font(.Pretendard.caption1)
            .foregroundStyle(Color.blackSeafoam)
        }
    }

    var nicknameBinding: Binding<String> {
        Binding(
            get: { viewModel.state.nickname },
            set: { viewModel.send(.nicknameChanged($0)) }
        )
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

    var passwordConfirmBinding: Binding<String> {
        Binding(
            get: { viewModel.state.passwordConfirm },
            set: { viewModel.send(.passwordConfirmChanged($0)) }
        )
    }
}

// MARK: - Input Field Builders

private extension SignUpView {

    // isValid: nil → 미입력(기본 테두리), true → 유효(테두리 변화 없음), false → 오류(빨간 테두리)
    func inputField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType = .default,
        isValid: Bool? = nil,
        trailingButton: (() -> Void)? = nil,
        trailingButtonLabel: String? = nil,
        trailingButtonEnabled: Bool = true,
        trailingButtonLoading: Bool = false,
        statusMessage: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray90)

            HStack(spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(Color.gray45)
                    TextField(placeholder, text: text)
                        .font(.Pretendard.body2)
                        .foregroundStyle(Color.gray90)
                        .keyboardType(keyboardType)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor(for: isValid), lineWidth: 1)
                }

                if let trailingButton, let trailingButtonLabel {
                    Button(action: trailingButton) {
                        Group {
                            if trailingButtonLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.8)
                            } else {
                                Text(trailingButtonLabel)
                                    .font(.Pretendard.caption1)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: 76, height: 52)
                        .background(trailingButtonEnabled ? Color.blackSeafoam : Color.gray30)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .disabled(!trailingButtonEnabled || trailingButtonLoading)
                }
            }

            if isValid == false {
                Text(validationMessage(for: label))
                    .font(.Pretendard.caption3)
                    .foregroundStyle(Color.rosyPunch)
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.Pretendard.caption3)
                    .foregroundStyle(Color.gray90)
            }
        }
    }

    func secureInputField(
        label: String,
        placeholder: String,
        text: Binding<String>,
        isVisible: Bool,
        isValid: Bool? = nil,
        hint: String? = nil,
        onToggleVisibility: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.Pretendard.caption1)
                .foregroundStyle(Color.gray90)

            HStack(spacing: 10) {
                Image(systemName: "lock")
                    .foregroundStyle(Color.gray45)

                Group {
                    if isVisible {
                        TextField(placeholder, text: text)
                    } else {
                        SecureField(placeholder, text: text)
                    }
                }
                .font(.Pretendard.body2)
                .foregroundStyle(Color.gray90)

                Button(action: onToggleVisibility) {
                    Image(systemName: isVisible ? "eye" : "eye.slash")
                        .foregroundStyle(Color.gray45)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor(for: isValid), lineWidth: 1)
            }

            // hint: 항상 표시 / 오류 메시지 우선
            if isValid == false {
                Text(validationMessage(for: label))
                    .font(.Pretendard.caption3)
                    .foregroundStyle(Color.rosyPunch)
            } else if let hint, isValid == nil {
                Text(hint)
                    .font(.Pretendard.caption3)
                    .foregroundStyle(Color.gray45)
            }
        }
    }

    // MARK: - Helpers

    func borderColor(for isValid: Bool?) -> Color {
        switch isValid {
        case .none:            return .gray15
        case .some(true):      return .gray15
        case .some(false):     return .rosyPunch
        }
    }

    func validationMessage(for label: String) -> String {
        switch label {
        case "닉네임":
            return "- . , ? * @ + ^ $ { } ( ) | [ ] \\ 는 사용할 수 없습니다"
        case "이메일":
            return "올바른 이메일 형식을 입력해주세요 (예: user@example.com)"
        case "비밀번호":
            return "8자 이상, 영문자·숫자·특수문자(@$!%*#?&)를 포함해야 합니다"
        case "비밀번호 확인":
            return "비밀번호가 일치하지 않습니다"
        default:
            return "올바르지 않은 형식입니다"
        }
    }
}
