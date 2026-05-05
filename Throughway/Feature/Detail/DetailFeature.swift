//
//  DetailFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum DetailFeature {
    struct State: BaseState {
        var detail: ActivityDetailDTO?
        var isLoading: Bool = false
        var selectedDateIndex: Int = 0
        var selectedTime: String?
        var keepOverride: (isKeep: Bool, keepCount: Int)? = nil
    }

    enum Intent: BaseIntent {
        case onAppear
        case dateSelected(Int)
        case timeSelected(String)
        case keepToggled
    }
}
