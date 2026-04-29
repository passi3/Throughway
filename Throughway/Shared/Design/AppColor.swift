//
//  AppColor.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import SwiftUI

extension Color {
    // MARK: - Brand
    static let blackSeafoam = Color(hex: "#4382AC")
    static let deepSeafoam  = Color(hex: "#7AB5DC")
    static let lightSeafoam = Color(hex: "#D6E5EA")
    static let rosyPunch    = Color(hex: "#F66490")

    // MARK: - GrayScale
    static let gray0   = Color(hex: "#FFFFFF")
    static let gray15  = Color(hex: "#D9D9D9")
    static let gray30  = Color(hex: "#B3B3B3")
    static let gray45  = Color(hex: "#8C8C8C")
    static let gray60  = Color(hex: "#666666")
    static let gray75  = Color(hex: "#404040")
    static let gray90  = Color(hex: "#1A1A1A")
    static let gray100 = Color(hex: "#000000")
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
