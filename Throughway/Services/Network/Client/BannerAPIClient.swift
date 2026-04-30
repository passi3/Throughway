//
//  BannerAPIClient.swift
//  Throughway
//
//  Created by passi on 4/29/26.
//

import Foundation

struct BannerAPIClient {
    var fetchMain: @Sendable () async throws -> BannerListResponseDTO
}

extension BannerAPIClient {
    static let live: BannerAPIClient = {
        let network = SharedNetwork.manager
        return Self(
            fetchMain: {
                try await network.request(BannerRouter.fetchMain)
            }
        )
    }()
}
