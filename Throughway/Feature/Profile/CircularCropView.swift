//
//  CircularCropView.swift
//  Throughway
//
//  Created by passi on 5/5/26.
//

import SwiftUI

struct CircularCropView: View {
    let image: UIImage
    let onConfirm: (Data) -> Void
    let onCancel: () -> Void

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let cropDiameter: CGFloat = 280

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .offset(offset)

                dimmingOverlay

                Circle()
                    .stroke(Color.white.opacity(0.8), lineWidth: 1)
                    .frame(width: cropDiameter, height: cropDiameter)
                    .allowsHitTesting(false)

                VStack {
                    HStack {
                        Button("취소") { onCancel() }
                            .font(.Pretendard.body3)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("완료") { confirm(screenSize: geo.size) }
                            .font(.Pretendard.body3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 60)
                    Spacer()
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(
                            width: lastOffset.width + value.translation.width,
                            height: lastOffset.height + value.translation.height
                        )
                    }
                    .onEnded { _ in lastOffset = offset }
                    .simultaneously(with:
                        MagnificationGesture()
                            .onChanged { value in scale = max(0.5, lastScale * value) }
                            .onEnded { _ in lastScale = scale }
                    )
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Views

    private var dimmingOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
            Circle()
                .frame(width: cropDiameter, height: cropDiameter)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    // MARK: - Logic

    private func confirm(screenSize: CGSize) {
        guard let cropped = crop(screenSize: screenSize),
              let data = cropped.jpegData(compressionQuality: 0.9) else { return }
        let kb = Double(data.count) / 1024
        print("[CropImage] 크롭 이미지 용량: \(String(format: "%.1f", kb)) KB (\(data.count) bytes)")
        onConfirm(data)
    }

    /// scaledToFit 기준의 자연 표시 크기
    private func fitSize(for imageSize: CGSize, in screenSize: CGSize) -> CGSize {
        let imageAspect = imageSize.width / imageSize.height
        let screenAspect = screenSize.width / screenSize.height
        if imageAspect > screenAspect {
            return CGSize(width: screenSize.width, height: screenSize.width / imageAspect)
        } else {
            return CGSize(width: screenSize.height * imageAspect, height: screenSize.height)
        }
    }

    /// 현재 offset/scale 상태에서 원형 크롭 영역을 UIImage로 추출
    private func crop(screenSize: CGSize) -> UIImage? {
        let natural = fitSize(for: image.size, in: screenSize)

        // 자연 크기(pt) → 원본 픽셀 변환 비율
        let pxPerPtX = image.size.width / natural.width
        let pxPerPtY = image.size.height / natural.height

        // 크롭 원의 반지름 (natural pt 기준)
        let cropRadius = cropDiameter / 2
        let cropRadiusNatural = cropRadius / scale

        // 크롭 원 중심이 이미지 위에서 어디에 해당하는지 (natural pt 기준)
        let cropCenterNaturalX = natural.width / 2 - offset.width / scale
        let cropCenterNaturalY = natural.height / 2 - offset.height / scale

        // 픽셀 rect
        let pixelRect = CGRect(
            x: (cropCenterNaturalX - cropRadiusNatural) * pxPerPtX,
            y: (cropCenterNaturalY - cropRadiusNatural) * pxPerPtY,
            width: cropRadiusNatural * 2 * pxPerPtX,
            height: cropRadiusNatural * 2 * pxPerPtY
        )

        let clamped = pixelRect.intersection(CGRect(origin: .zero, size: image.size))
        guard !clamped.isNull, let cgCrop = image.cgImage?.cropping(to: clamped) else { return nil }

        // 512×512 정사각형으로 렌더링
        let outputSize = CGSize(width: 512, height: 512)
        let renderer = UIGraphicsImageRenderer(size: outputSize)
        return renderer.image { _ in
            UIImage(cgImage: cgCrop, scale: image.scale, orientation: image.imageOrientation)
                .draw(in: CGRect(origin: .zero, size: outputSize))
        }
    }
}

// MARK: - UIImage orientation normalization

extension UIImage {
    func normalized() -> UIImage {
        guard imageOrientation != .up else { return self }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }
}
