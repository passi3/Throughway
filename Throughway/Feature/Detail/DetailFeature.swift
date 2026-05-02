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
        var selectedMonth: Int = 0
        var selectedTime: String?
    }

    enum Intent: BaseIntent {
        case onAppear
        case monthSelected(Int)
        case timeSelected(String)
    }
}
