//
//  AuthImageModifier.swift
//  Throughway
//
//  Created by passi on 5/3/26.
//

import Foundation
import Kingfisher

final class AuthImageModifier: AsyncImageDownloadRequestModifier {

    let onDownloadTaskStarted: (@Sendable (DownloadTask?) -> Void)? = nil

    func modified(for request: URLRequest) async -> URLRequest? {
        var req = request
        req.setValue(APIConstants.sesacKey, forHTTPHeaderField: "SeSACKey")
        if let token = await TokenClient.live.loadAccessToken() {
            req.setValue(token, forHTTPHeaderField: "Authorization")
        }
        return req
    }
}

// MARK: - URL helpers

extension String {
    /// 서버 상대경로를 절대 URL로 변환 (baseURL + /v1 + path)
    var serverImageURL: URL? {
        URL(string: APIConstants.baseURL + "/v1" + self)
    }
}
