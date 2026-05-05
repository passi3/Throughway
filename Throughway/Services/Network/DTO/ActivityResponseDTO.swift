//
//  ActivityResponseDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

// MARK: - 목록 조회

struct ActivityListResponseDTO: Decodable, Sendable {
    let data: [ActivitySummaryDTO]
    let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor = "next_cursor"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent([ActivitySummaryDTO].self, forKey: .data) ?? []
        nextCursor = container.decodeLossyStringIfPresent(forKey: .nextCursor)
    }
}

struct ActivitySummaryDTO: Decodable, Sendable {
    let activityId: String
    let title: String
    let country: String
    let category: String
    let thumbnails: [String]
    let geolocation: GeolocationDTO
    let price: ActivityPriceDTO
    let tags: [String]
    let pointReward: Int
    let isAdvertisement: Bool
    let isKeep: Bool
    let keepCount: Int

    enum CodingKeys: String, CodingKey {
        case activityId     = "activity_id"
        case title
        case country
        case category
        case thumbnails
        case geolocation
        case price
        case tags
        case pointReward    = "point_reward"
        case isAdvertisement = "is_advertisement"
        case isKeep         = "is_keep"
        case keepCount      = "keep_count"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityId = container.decodeLossyString(forKey: .activityId)
        title = try container.decode(String.self, forKey: .title)
        country = try container.decode(String.self, forKey: .country)
        category = try container.decode(String.self, forKey: .category)
        thumbnails = try container.decodeIfPresent([String].self, forKey: .thumbnails) ?? []
        geolocation = try container.decode(GeolocationDTO.self, forKey: .geolocation)
        price = try container.decode(ActivityPriceDTO.self, forKey: .price)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        pointReward = try container.decodeIfPresent(Int.self, forKey: .pointReward) ?? 0
        isAdvertisement = try container.decodeIfPresent(Bool.self, forKey: .isAdvertisement) ?? false
        isKeep = try container.decodeIfPresent(Bool.self, forKey: .isKeep) ?? false
        keepCount = try container.decodeIfPresent(Int.self, forKey: .keepCount) ?? 0
    }
}

extension ActivitySummaryDTO {
    init(_ base: ActivitySummaryDTO, isKeep: Bool, keepCount: Int) {
        self.activityId      = base.activityId
        self.title           = base.title
        self.country         = base.country
        self.category        = base.category
        self.thumbnails      = base.thumbnails
        self.geolocation     = base.geolocation
        self.price           = base.price
        self.tags            = base.tags
        self.pointReward     = base.pointReward
        self.isAdvertisement = base.isAdvertisement
        self.isKeep          = isKeep
        self.keepCount       = keepCount
    }
}

struct GeolocationDTO: Decodable, Sendable {
    let longitude: Double
    let latitude: Double
}

struct ActivityPriceDTO: Decodable, Sendable {
    let original: Int
    let final: Int
}

// MARK: - 상세 조회 (목록 필드 + 추가 정보)

struct ActivityDetailDTO: Decodable, Sendable {
    let activityId: String
    let title: String
    let country: String
    let category: String
    let thumbnails: [String]
    let geolocation: GeolocationDTO
    let startDate: String?
    let endDate: String?
    let price: ActivityPriceDTO
    let tags: [String]
    let pointReward: Int
    let isAdvertisement: Bool
    let isKeep: Bool
    let keepCount: Int
    let totalOrderCount: Int
    let rating: Double?
    let reviewCount: Int?
    let description: String?
    let schedule: [ActivityScheduleItemDTO]
    let restrictions: ActivityRestrictionsDTO?
    let reservationList: [ActivityReservationDTO]
    let creator: ActivityCreatorDTO?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case activityId      = "activity_id"
        case title
        case country
        case category
        case thumbnails
        case geolocation
        case startDate       = "start_date"
        case endDate         = "end_date"
        case price
        case tags
        case pointReward     = "point_reward"
        case isAdvertisement = "is_advertisement"
        case isKeep          = "is_keep"
        case keepCount       = "keep_count"
        case totalOrderCount = "total_order_count"
        case rating
        case reviewCount     = "review_count"
        case description
        case schedule
        case restrictions
        case reservationList = "reservation_list"
        case creator
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activityId      = container.decodeLossyString(forKey: .activityId)
        title           = try container.decode(String.self, forKey: .title)
        country         = try container.decode(String.self, forKey: .country)
        category        = try container.decode(String.self, forKey: .category)
        thumbnails      = try container.decodeIfPresent([String].self, forKey: .thumbnails) ?? []
        geolocation     = try container.decode(GeolocationDTO.self, forKey: .geolocation)
        startDate       = container.decodeLossyStringIfPresent(forKey: .startDate)
        endDate         = container.decodeLossyStringIfPresent(forKey: .endDate)
        price           = try container.decode(ActivityPriceDTO.self, forKey: .price)
        tags            = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        pointReward     = try container.decodeIfPresent(Int.self, forKey: .pointReward) ?? 0
        isAdvertisement = try container.decodeIfPresent(Bool.self, forKey: .isAdvertisement) ?? false
        isKeep          = try container.decodeIfPresent(Bool.self, forKey: .isKeep) ?? false
        keepCount       = try container.decodeIfPresent(Int.self, forKey: .keepCount) ?? 0
        totalOrderCount = try container.decodeIfPresent(Int.self, forKey: .totalOrderCount) ?? 0
        rating          = try container.decodeIfPresent(Double.self, forKey: .rating)
        reviewCount     = try container.decodeIfPresent(Int.self, forKey: .reviewCount)
        description     = try container.decodeIfPresent(String.self, forKey: .description)
        schedule        = try container.decodeIfPresent([ActivityScheduleItemDTO].self, forKey: .schedule) ?? []
        restrictions    = try container.decodeIfPresent(ActivityRestrictionsDTO.self, forKey: .restrictions)
        reservationList = try container.decodeIfPresent([ActivityReservationDTO].self, forKey: .reservationList) ?? []
        creator         = try container.decodeIfPresent(ActivityCreatorDTO.self, forKey: .creator)
        createdAt       = container.decodeLossyStringIfPresent(forKey: .createdAt)
        updatedAt       = container.decodeLossyStringIfPresent(forKey: .updatedAt)
    }
}

struct ActivityRestrictionsDTO: Decodable, Sendable {
    let minAge: Int?
    let minHeight: Int?
    let maxParticipants: Int?

    enum CodingKeys: String, CodingKey {
        case minAge          = "min_age"
        case minHeight       = "min_height"
        case maxParticipants = "max_participants"
    }
}

struct ActivityReservationDTO: Decodable, Sendable {
    let itemName: String
    let times: [ActivityTimeSlotDTO]

    enum CodingKeys: String, CodingKey {
        case itemName = "item_name"
        case times
    }
}

struct ActivityTimeSlotDTO: Decodable, Sendable {
    let time: String
    let isReserved: Bool

    enum CodingKeys: String, CodingKey {
        case time
        case isReserved = "is_reserved"
    }
}

struct ActivityCreatorDTO: Decodable, Sendable {
    let userId: String
    let nick: String
    let profileImage: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case nick
        case profileImage = "profile_image"
    }
}

struct ActivityScheduleItemDTO: Decodable, Sendable {
    let duration: String
    let description: String
}

// MARK: - 킵 토글

struct KeepToggleResponseDTO: Decodable, Sendable {
    let keepStatus: Bool

    enum CodingKeys: String, CodingKey {
        case keepStatus = "keep_status"
    }
}

// MARK: - 검색

struct ActivitySearchResponseDTO: Decodable, Sendable {
    let data: [ActivitySummaryDTO]
}

private extension KeyedDecodingContainer {
    func decodeLossyString(forKey key: Key) -> String {
        if let value = try? decode(String.self, forKey: key) {
            return value
        }
        if let value = try? decode(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decode(Double.self, forKey: key) {
            return String(value)
        }
        return ""
    }

    func decodeLossyStringIfPresent(forKey key: Key) -> String? {
        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }
        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }
        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }
        return nil
    }
}
