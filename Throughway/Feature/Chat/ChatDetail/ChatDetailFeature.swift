//
//  ChatDetailFeature.swift
//  Throughway
//
//  Created by passi on 5/2/26.
//

import Foundation

// MARK: - File Upload Types

struct PendingFilePickResult: Sendable {
    let data: Data
    let fileName: String
    let ext: String
}

struct PendingFile: Identifiable, Sendable {
    let id: UUID
    let data: Data
    let fileName: String
    let mimeType: String
}

// MARK: - Feature

enum ChatDetailFeature {
    struct State: BaseState {
        var messages: [ChatMessageDTO] = []
        var inputText: String = ""
        var isLoadingHistory: Bool = false
        var isSending: Bool = false
        var myUserId: String = ""
        var updatedOpponentProfile: ChatParticipantDTO? = nil
        var pendingFiles: [PendingFile] = []
        var fileUploadError: String? = nil
    }

    enum Intent: BaseIntent {
        case onAppear
        case onDisappear
        case inputChanged(String)
        case sendTapped
        case dismissProfileUpdate
        case filesPicked([PendingFilePickResult])
        case removePendingFile(UUID)
        case dismissFileUploadError
    }
}
