//
//  ChatRepository.swift
//  Throughway
//
//  Created by passi on 5/3/26.
//

import Foundation
import RealmSwift

final class ChatRepository {
    private let realm: Realm

    init() {
        self.realm = try! Realm()
    }

    // createdAt 오름차순(오래된 것부터) 정렬
    func fetchMessages(roomId: String) -> [ChatMessageDTO] {
        realm.objects(ChatMessageObject.self)
            .where { $0.roomId == roomId }
            .sorted(byKeyPath: "createdAt", ascending: true)
            .map { $0.toDTO() }
    }

    // 마지막 메시지의 createdAt — cursor_date로 사용
    func lastMessageDate(roomId: String) -> String? {
        realm.objects(ChatMessageObject.self)
            .where { $0.roomId == roomId }
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first?
            .createdAt
    }

    // upsert — primaryKey(chatId) 기준 중복 방지
    func save(messages: [ChatMessageDTO]) {
        let objects = messages.map { $0.toObject() }
        try? realm.write {
            realm.add(objects, update: .modified)
        }
    }

    func save(message: ChatMessageDTO) {
        try? realm.write {
            realm.add(message.toObject(), update: .modified)
        }
    }
}
