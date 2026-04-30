//
//  BannerDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

struct BannerItemDTO: Decodable, Sendable {
    let name: String
    let imageUrl: String
    let payload: BannerPayloadDTO
}

struct BannerPayloadDTO: Decodable, Sendable {
    let type: String
    let value: String
}

struct BannerListResponseDTO: Decodable, Sendable {
    let data: [BannerItemDTO]
}
