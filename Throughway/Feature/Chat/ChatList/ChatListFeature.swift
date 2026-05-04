//
//  ChatListFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

enum ChatListFeature {
    struct State: BaseState {
        var rooms: [ChatRoomDTO] = []
        var isLoading: Bool = false
        var selectedRoom: ChatRoomDTO? = nil
        var myUserId: String = ""
        var roomLastMessages: [String: ChatMessageDTO] = [:]
    }

    enum Intent: BaseIntent {
        case onAppear
        case onDisappear
        case refresh
        case roomTapped(ChatRoomDTO)
        case clearSelection
    }
}
