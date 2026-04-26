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
extension Font {
    enum Pretendard {
        static let title1   = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 20)
        static let body1    = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 16)
        static let body2    = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 14)
        static let body3    = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 13)
        static let caption1 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 12)
        static let caption2 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 10)
        static let caption3 = AppFontLoader.makeFont(name: "Pretendard-Regular", size: 8)
    }
}

// MARK: - Paperlogy
extension Font {
    enum Paperlogy {
        static let title1   = AppFontLoader.makeFont(name: "Paperlogy-Regular", size: 26)
        static let body1    = AppFontLoader.makeFont(name: "Paperlogy-Regular", size: 22)
        static let caption1 = AppFontLoader.makeFont(name: "Paperlogy-Regular", size: 14)
    }
}
