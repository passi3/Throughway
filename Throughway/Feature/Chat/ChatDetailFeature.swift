//
//  ChatDetailFeature.swift
//  Throughway
//

import Foundation

enum ChatDetailFeature {
    struct State: BaseState {
        var messages: [ChatMessageDTO] = []
        var inputText: String = ""
        var isLoadingHistory: Bool = false
        var isSending: Bool = false
        var myUserId: String = ""
    }

    enum Intent: BaseIntent {
        case onAppear
        case onDisappear
        case inputChanged(String)
        case sendTapped
    }
}
