//
//  ActivityRequestDTO.swift
//  Throughway
//
//  Created by passi on 4/30/26.
//

import Foundation

struct KeepToggleRequestDTO: Encodable, Sendable {
    let keepStatus: Bool

    enum CodingKeys: String, CodingKey {
        case keepStatus = "keep_status"
    }
}
