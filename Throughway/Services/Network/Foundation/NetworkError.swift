//
//  NetworkError.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case encodingFailed
    case decodingFailed(Error)

    // HTTP Status Errors
    case badRequest(String)         // 400
    case unauthorized               // 401
    case forbidden                  // 403
    case notFound                   // 404
    case conflict(String)           // 409
    case tooManyRequests            // 429
    case serverError                // 500+
    case unknown(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "잘못된 URL입니다."
        case .invalidResponse:       return "유효하지 않은 응답입니다."
        case .encodingFailed:        return "요청 인코딩에 실패했습니다."
        case .decodingFailed(let e): return "응답 디코딩 실패: \(e.localizedDescription)"
        case .badRequest(let msg):   return msg
        case .unauthorized:          return "인증이 필요합니다."
        case .forbidden:             return "접근 권한이 없습니다."
        case .notFound:              return "요청한 리소스를 찾을 수 없습니다."
        case .conflict(let msg):     return msg
        case .tooManyRequests:       return "요청이 너무 많습니다. 잠시 후 다시 시도해주세요."
        case .serverError:           return "서버 오류가 발생했습니다."
        case .unknown(let code, let msg): return "오류 \(code): \(msg)"
        }
    }
}
