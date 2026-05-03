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
    }

    enum Intent: BaseIntent {
        case onAppear
        case dateSelected(Int)
        case timeSelected(String)
    }
}
