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

    // MARK: - 메시지 조회

    func fetchMessages(roomId: String) -> [ChatMessageDTO] {
        realm.objects(ChatMessageObject.self)
            .where { $0.roomId == roomId }
            .sorted(byKeyPath: "createdAt", ascending: true)
            .map { $0.toDTO() }
    }

    func lastMessageDate(roomId: String) -> String? {
        realm.objects(ChatMessageObject.self)
            .where { $0.roomId == roomId }
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first?
            .createdAt
    }

    func lastMessage(roomId: String) -> ChatMessageDTO? {
        realm.objects(ChatMessageObject.self)
            .where { $0.roomId == roomId }
            .sorted(byKeyPath: "createdAt", ascending: false)
            .first?
            .toDTO()
    }

    // MARK: - 메시지 저장

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

    // MARK: - lastSeenAt 관리

    func lastSeenAt(roomId: String) -> String? {
        realm.object(ofType: ChatRoomLastSeenRecord.self, forPrimaryKey: roomId)?.lastSeenAt
    }

    func updateLastSeen(roomId: String) {
        let record = ChatRoomLastSeenRecord()
        record.roomId = roomId
        record.lastSeenAt = ISO8601DateFormatter().string(from: Date())
        try? realm.write {
            realm.add(record, update: .modified)
        }
    }

    // MARK: - 삭제

    /// 채팅방 삭제: 메시지 삭제 + lastSeenAt을 현재 시점으로 갱신
    /// → 재진입 시 삭제 이후 메시지만 fetch
    func deleteMessages(roomId: String) {
        let objects = realm.objects(ChatMessageObject.self)
            .where { $0.roomId == roomId }
        let record = ChatRoomLastSeenRecord()
        record.roomId = roomId
        record.lastSeenAt = ISO8601DateFormatter().string(from: Date())
        try? realm.write {
            realm.delete(objects)
            realm.add(record, update: .modified)
        }
    }

    /// 로그아웃 시 전체 삭제 (lastSeenAt 포함)
    func deleteAll() {
        try? realm.write {
            realm.deleteAll()
        }
    }
}
