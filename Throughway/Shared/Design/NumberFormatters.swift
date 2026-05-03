//
//  NumberFormatters.swift
//  Throughway
//
//  Created by passi on 5/3/26.
//

import Foundation

enum AppFormatter {
    static let won: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let serverDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()

    static let chipDate: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M월 d일"
        f.locale = Locale(identifier: "ko_KR")
        return f
    }()
}

extension Int {
    var wonFormatted: String {
        (AppFormatter.won.string(from: NSNumber(value: self)) ?? "\(self)") + "원"
    }
}
