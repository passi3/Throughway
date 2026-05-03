//
//  ChatListFeature.swift
//  Throughway
//

import Foundation

enum ChatListFeature {
    struct State: BaseState {
        var rooms: [ChatRoomDTO] = []
        var isLoading: Bool = false
        var selectedRoom: ChatRoomDTO? = nil
        var myUserId: String = ""
    }

    enum Intent: BaseIntent {
        case onAppear
        case refresh
        case roomTapped(ChatRoomDTO)
        case clearSelection
    }
}
