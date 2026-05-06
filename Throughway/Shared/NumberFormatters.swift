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
}

extension Int {
    var wonFormatted: String {
        (AppFormatter.won.string(from: NSNumber(value: self)) ?? "\(self)") + "원"
    }
}
