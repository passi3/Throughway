//
//  ChatDetailFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum ChatDetailFeature {
    struct State: BaseState {
        var messages: [ChatMessageDTO] = []
        var inputText: String = ""
        var isLoadingHistory: Bool = false
        var isSending: Bool = false
        var myUserId: String = ""
        var updatedOpponentProfile: ChatParticipantDTO? = nil
    }

    enum Intent: BaseIntent {
        case onAppear
        case onDisappear
        case inputChanged(String)
        case sendTapped
        case dismissProfileUpdate
    }
}
