//
//  AppFont.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import SwiftUI
import UIKit

private enum AppFontLoader {
    static func makeFont(name: String, size: CGFloat) -> Font {
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size)
    }
}

// MARK: - Pretendard
// kYPPp 디자인 시스템 타이포그래피 기준
extension Font {
    enum Pretendard {
        // Title — 페이지·섹션 제목
        /// 28pt Bold  ·  회원가입·채팅 등 대형 타이틀
        static let title1 = AppFontLoader.makeFont(name: "Pretendard-Bold", size: 28)
        /// 22pt Bold  ·  프로필 이름, 섹션 헤더
        static let title2 = AppFontLoader.makeFont(name: "Pretendard-Bold", size: 22)
        /// 18pt SemiBold  ·  카드 타이틀
        static let title3 = AppFontLoader.makeFont(name: "Pretendard-SemiBold", size: 18)

        // Body — 본문 텍스트
        /// 16pt SemiBold  ·  버튼 레이블, 강조 텍스트
        static let body1 = AppFontLoader.makeFont(name: "Pretendard-SemiBold", size: 16)
        /// 15pt SemiBold  ·  네비게이션 바 타이틀
        static let body2 = AppFontLoader.makeFont(name: "Pretendard-SemiBold", size: 15)
        /// 14pt Regular  ·  기본 본문
        static let body3 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 14)
        /// 13pt Regular  ·  보조 본문, 댓글
        static let body4 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 13)

        // Caption — 부가 정보
        /// 12pt SemiBold  ·  입력 필드 레이블
        static let caption1 = AppFontLoader.makeFont(name: "Pretendard-SemiBold", size: 12)
        /// 12pt Regular  ·  설명, 힌트
        static let caption2 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 12)
        /// 11pt Regular  ·  날짜, 메타 정보
        static let caption3 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 11)
        /// 10pt Regular  ·  탭 바 레이블
        static let caption4 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 10)
    }
}

// MARK: - Paperlogy
// 앱 브랜드 로고 전용
extension Font {
    enum Paperlogy {
        /// 34pt  ·  앱 로고 "Throughway"
        static let brand    = AppFontLoader.makeFont(name: "Paperlogy-Regular", size: 34)
        /// 26pt  ·  대형 브랜드 텍스트
        static let title1   = AppFontLoader.makeFont(name: "Paperlogy-Regular", size: 26)
        /// 22pt  ·  중형 브랜드 텍스트
        static let title2   = AppFontLoader.makeFont(name: "Paperlogy-Regular", size: 22)
        /// 14pt  ·  브랜드 캡션
        static let caption1 = AppFontLoader.makeFont(name: "Paperlogy-Regular", size: 14)
    }
}
