//
//  AppColor.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import SwiftUI

extension Color {
    // MARK: - Brand
    /// #006D77  메인 브랜드 컬러 (버튼, 액티브 탭, 링크)
    static let primary      = Color(hex: "#006D77")
    /// #E0F2F4  브랜드 연한 배경 (배지, 칩 배경)
    static let primaryLight = Color(hex: "#E0F2F4")

    // MARK: - Text
    /// #1F2937  기본 텍스트
    static let textPrimary   = Color(hex: "#1F2937")
    /// #6B7280  보조 텍스트
    static let textSecondary = Color(hex: "#6B7280")
    /// #9CA3AF  비활성 / 힌트 텍스트
    static let textTertiary  = Color(hex: "#9CA3AF")

    // MARK: - Background
    /// #FFFFFF  카드, 입력 필드, 탭바 배경
    static let bgPrimary   = Color(hex: "#FFFFFF")
    /// #F9FAFB  화면 기본 배경
    static let bgSecondary = Color(hex: "#F9FAFB")
    /// #F3F4F6  비활성 칩, 구분 영역
    static let bgTertiary  = Color(hex: "#F3F4F6")

    // MARK: - Border
    /// #E5E7EB  스트로크, 구분선
    static let border = Color(hex: "#E5E7EB")

    // MARK: - Semantic
    /// #111827  다크 그라디언트, 오버레이
    static let dark  = Color(hex: "#111827")
    /// #EF4444  에러, 경고
    static let error = Color(hex: "#EF4444")
}

private extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let r, g, b, a: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >>  8) & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
            a = 1
        case 8:
            r = Double((int >> 24) & 0xFF) / 255
            g = Double((int >> 16) & 0xFF) / 255
            b = Double((int >>  8) & 0xFF) / 255
            a = Double( int        & 0xFF) / 255
        default:
            r = 0; g = 0; b = 0; a = 1
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
