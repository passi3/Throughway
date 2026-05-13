//
//  CreatePostView.swift
//  Throughway
//
//  Created by passi on 5/11/26.
//

import SwiftUI
import PhotosUI
import Kingfisher

struct CreatePostView: View {
    @StateObject private var viewModel: CreatePostViewModel
    @State private var selectedPhotoItems: [PhotosPickerItem] = []
    @Environment(\.dismiss) private var dismiss

    private let countries = ["대한민국", "일본", "호주", "필리핀", "태국"]
    private let categories = ["투어", "관광", "패키지", "익사이팅", "체험"]

    init(latitude: Double?, longitude: Double?) {
        _viewModel = StateObject(wrappedValue: CreatePostViewModel(
            latitude: latitude,
            longitude: longitude
        ))
    }

    init(post: PostDTO, latitude: Double?, longitude: Double?) {
        _viewModel = StateObject(wrappedValue: CreatePostViewModel(
            post: post,
            latitude: latitude,
            longitude: longitude
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    pickerSection
                    titleSection
                    contentSection
                    photoSection

                    if let error = viewModel.state.error {
                        Text(error)
                            .font(.Pretendard.caption2)
                            .foregroundStyle(.red)
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.bgPrimary)
            .navigationTitle(viewModel.state.postId != nil ? "포스트 수정" : "포스트 등록")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                        .foregroundStyle(Color.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    submitButton
                }
            }
            .onChange(of: selectedPhotoItems) { _, items in
                loadPhotos(from: items)
            }
            .onChange(of: viewModel.state.didFinish) { _, done in
                if done { dismiss() }
            }
        }
    }

    private func loadPhotos(from items: [PhotosPickerItem]) {
        Task {
            var loaded: [Data] = []
            for item in items {
                guard let data = try? await item.loadTransferable(type: Data.self) else { continue }
                loaded.append(data)
            }
            selectedPhotoItems = []
            viewModel.send(.photosSelected(loaded))
        }
    }
}

// MARK: - Sections

private extension CreatePostView {

    var pickerSection: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("국가")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.textSecondary)

                Menu {
                    ForEach(countries, id: \.self) { country in
                        Button(country) {
                            viewModel.send(.countryChanged(country))
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.state.country ?? "선택")
                            .foregroundStyle(viewModel.state.country != nil ? Color.textPrimary : Color.textTertiary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .font(.Pretendard.body3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.bgPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.border, lineWidth: 1)
                    )
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("카테고리")
                    .font(.Pretendard.caption2)
                    .foregroundStyle(Color.textSecondary)

                Menu {
                    ForEach(categories, id: \.self) { category in
                        Button(category) {
                            viewModel.send(.categoryChanged(category))
                        }
                    }
                } label: {
                    HStack {
                        Text(viewModel.state.category ?? "선택")
                            .foregroundStyle(viewModel.state.category != nil ? Color.textPrimary : Color.textTertiary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .font(.Pretendard.body3)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.bgPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.border, lineWidth: 1)
                    )
                }
            }
        }
    }

    var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("제목")
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.textSecondary)

            TextField("제목을 입력하세요", text: Binding(
                get: { viewModel.state.title },
                set: { viewModel.send(.titleChanged($0)) }
            ))
            .font(.Pretendard.body3)
            .foregroundStyle(Color.textPrimary)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.bgPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
    }

    var contentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("내용")
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.textSecondary)

            TextEditor(text: Binding(
                get: { viewModel.state.content },
                set: { viewModel.send(.contentChanged($0)) }
            ))
            .font(.Pretendard.body4)
            .foregroundStyle(Color.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 120)
            .background(Color.bgPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.border, lineWidth: 1)
            )
        }
    }

    var photoSection: some View {
        let totalCount = viewModel.state.existingFilePaths.count + viewModel.state.selectedImageData.count

        return VStack(alignment: .leading, spacing: 6) {
            Text("사진")
                .font(.Pretendard.caption2)
                .foregroundStyle(Color.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    PhotosPicker(
                        selection: $selectedPhotoItems,
                        maxSelectionCount: max(0, 5 - totalCount),
                        matching: .images
                    ) {
                        VStack(spacing: 6) {
                            Image(systemName: "camera")
                                .font(.system(size: 22))
                                .foregroundStyle(Color.textTertiary)
                            Text("\(totalCount)/5")
                                .font(.Pretendard.caption3)
                                .foregroundStyle(Color.textTertiary)
                        }
                        .frame(width: 72, height: 72)
                        .background(Color.bgPrimary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.border, lineWidth: 1)
                        )
                    }
                    .disabled(totalCount >= 5)

                    // 기존 서버 이미지
                    ForEach(Array(viewModel.state.existingFilePaths.enumerated()), id: \.offset) { index, path in
                        ZStack(alignment: .topTrailing) {
                            KFImage(path.serverImageURL)
                                .requestModifier(AuthImageModifier())
                                .placeholder {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.bgTertiary)
                                }
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(RoundedRectangle(cornerRadius: 10))

                            Button {
                                viewModel.send(.removeExistingPhoto(index))
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(Color.bgPrimary)
                                    .background(Circle().fill(Color.textPrimary.opacity(0.6)))
                            }
                            .offset(x: 4, y: -4)
                        }
                    }

                    // 새로 선택한 이미지
                    ForEach(Array(viewModel.state.selectedImageData.enumerated()), id: \.offset) { index, data in
                        if let uiImage = UIImage(data: data) {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                Button {
                                    viewModel.send(.removePhoto(index))
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.bgPrimary)
                                        .background(Circle().fill(Color.textPrimary.opacity(0.6)))
                                }
                                .offset(x: 4, y: -4)
                            }
                        }
                    }
                }
            }
        }
    }

    var submitButton: some View {
        Button {
            viewModel.send(.submit)
        } label: {
            if viewModel.state.isSubmitting {
                ProgressView()
                    .tint(Color.primary)
            } else {
                Text(viewModel.state.postId != nil ? "저장" : "등록")
                    .fontWeight(.semibold)
                    .foregroundStyle(isFormValid ? Color.primary : Color.textTertiary)
            }
        }
        .disabled(!isFormValid || viewModel.state.isSubmitting)
    }

    var isFormValid: Bool {
        viewModel.state.country != nil
        && viewModel.state.category != nil
        && !viewModel.state.title.trimmingCharacters(in: .whitespaces).isEmpty
        && !viewModel.state.content.trimmingCharacters(in: .whitespaces).isEmpty
    }
}
