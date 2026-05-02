//
//  BaseMVIViewModel.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation
import Combine

protocol BaseState { }

protocol BaseIntent { }

@MainActor
class BaseViewModel<State: BaseState, Intent: BaseIntent>: NSObject, ObservableObject {
    @Published private(set) var state: State

    init(initialState: State) {
        self.state = initialState
        super.init()
    }

    func send(_ intent: Intent) {
        fatalError("send(_:) must be overridden")
    }

    func reduce(_ mutate: (inout State) -> Void) {
        mutate(&state)
    }
}
