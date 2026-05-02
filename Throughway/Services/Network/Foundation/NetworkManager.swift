//
//  NetworkManager.swift
//  Throughway
//
//  Created by passi on 4/26/26.
//

import Foundation
import Alamofire

/// 앱 전체에서 단일 NetworkManager 인스턴스를 공유합니다.
/// 모든 APIClient는 이 manager를 통해 요청합니다.
enum SharedNetwork {
    static let manager: NetworkManager = {
        let tokenClient = TokenClient.live
        return NetworkManager(
            loadAccessToken: {
                await tokenClient.loadAccessToken()
            },
            loadRefreshToken: {
                await tokenClient.loadRefreshToken()
            },
            saveTokens: { tokens in
                try await tokenClient.save(tokens)
            },
            clearTokens: {
                await tokenClient.clear()
            },
            refreshTarget: { refreshToken in
                UserRouter.refreshToken(.init(refreshToken: refreshToken))
            }
        )
    }()
}

// MARK: - NetworkManager

final class NetworkManager: @unchecked Sendable {
    private let session: Session

    init(
        loadAccessToken:  @escaping @Sendable () async -> String?,
        loadRefreshToken: @escaping @Sendable () async -> String?,
        saveTokens:       @escaping @Sendable (AuthTokens) async throws -> Void,
        clearTokens:      @escaping @Sendable () async -> Void,
        refreshTarget:    @escaping @Sendable (String) -> any TargetType
    ) {
        let interceptor = AuthInterceptor(
            loadAccessToken:  loadAccessToken,
            loadRefreshToken: loadRefreshToken,
            saveTokens:       saveTokens,
            clearTokens:      clearTokens,
            refreshTarget:    refreshTarget
        )
        let config = URLSessionConfiguration.af.default
        config.timeoutIntervalForRequest = 30
        self.session = Session(configuration: config, interceptor: interceptor)
    }

    // MARK: - Public Interface

    /// Decodable 응답
    func request<T: Decodable>(_ target: any TargetType, as type: T.Type = T.self) async throws -> T {
        if case .multipart(let body) = target.body {
            return try await uploadMultipart(body, target: target)
        }
        let urlRequest = try buildURLRequest(from: target)
        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response
        Self.logResponseIfNeeded(response)
        let data = try extractData(from: response)
        return try decode(data, as: type)
    }

    /// 빈 응답 (204, 200 no body)
    func request(_ target: any TargetType) async throws {
        let urlRequest = try buildURLRequest(from: target)
        let response = await session
            .request(urlRequest)
            .validate(statusCode: 200..<300)
            .serializingData()
            .response
        Self.logResponseIfNeeded(response)
        _ = try extractData(from: response)
    }
}

// MARK: - Private

private extension NetworkManager {
    static let authorizationMarkerHeader = "X-Requires-Authorization"
    static let newActivitiesPath = "/v1/activities/new"
    static let geolocationPostsPath = "/v1/posts/geolocation"

    func buildURLRequest(from target: any TargetType) throws -> URLRequest {
        guard var components = URLComponents(string: target.baseURL + target.path) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = target.queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.method = target.method
        target.headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }
        if target.requiresAuthorization {
            urlRequest.setValue("true", forHTTPHeaderField: Self.authorizationMarkerHeader)
        }

        if case .json(let encodable) = target.body {
            do {
                urlRequest.httpBody = try JSONEncoder().encode(encodable)
            } catch {
                throw NetworkError.encodingFailed
            }
        }

        return urlRequest
    }

    func uploadMultipart<T: Decodable>(_ body: MultipartBody, target: any TargetType) async throws -> T {
        let urlRequest = try buildURLRequest(from: target)

        let response = await session.upload(
            multipartFormData: { formData in
                for part in body.parts {
                    formData.append(
                        part.data,
                        withName: part.name,
                        fileName: part.fileName,
                        mimeType: part.mimeType
                    )
                }
            },
            with: urlRequest
        )
        .validate(statusCode: 200..<300)
        .serializingData()
        .response

        Self.logResponseIfNeeded(response)
        let data = try extractData(from: response)
        return try decode(data, as: T.self)
    }

    func extractData(from response: DataResponse<Data, AFError>) throws -> Data {
        switch response.result {
        case .success(let data):
            return data
        case .failure:
            throw mapError(statusCode: response.response?.statusCode, data: response.data)
        }
    }

    func mapError(statusCode: Int?, data: Data?) -> NetworkError {
        switch statusCode {
        case 400:
            return .badRequest(parseMessage(from: data) ?? "필수값을 채워주세요.")
        case 401:
            return .unauthorized
        case 403:
            return .forbidden
        case 404:
            return .notFound
        case 409:
            return .conflict(parseMessage(from: data) ?? "이미 존재하는 데이터입니다.")
        case 429:
            return .tooManyRequests
        case let code where (code ?? 0) >= 500:
            return .serverError
        default:
            let code = statusCode ?? -1
            return .unknown(code, parseMessage(from: data) ?? "알 수 없는 오류")
        }
    }

    func decode<T: Decodable>(_ data: Data, as type: T.Type) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    func parseMessage(from data: Data?) -> String? {
        guard let data else { return nil }
        return try? JSONDecoder().decode(ErrorResponseDTO.self, from: data).message
    }

    static func logIfNeeded(_ request: URLRequest) {
        guard let path = request.url?.path,
              path == newActivitiesPath || path == geolocationPostsPath else { return }
        let url = request.url?.absoluteString ?? "<nil>"
        let authorization = request.value(forHTTPHeaderField: "Authorization") ?? "<nil>"
        let sesacKey = request.value(forHTTPHeaderField: "SeSACKey") ?? "<nil>"
        print("[Network] \(request.httpMethod ?? "GET") \(url)")
        print("[Network] Authorization: \(authorization)")
        print("[Network] SeSACKey: \(sesacKey)")
    }

    static func logResponseIfNeeded(_ response: DataResponse<Data, AFError>) {
        guard let path = response.request?.url?.path,
              path == newActivitiesPath || path == geolocationPostsPath else { return }
        let statusCode = response.response?.statusCode ?? -1
        let body = response.data.flatMap { String(data: $0, encoding: .utf8) } ?? "<empty>"
        print("[Network] Response Status: \(statusCode)")
        print("[Network] Response Body: \(body)")
    }
}

// MARK: - AuthInterceptor

private final class AuthInterceptor: RequestInterceptor, @unchecked Sendable {
    private let loadAccessToken:  @Sendable () async -> String?
    private let loadRefreshToken: @Sendable () async -> String?
    private let saveTokens:       @Sendable (AuthTokens) async throws -> Void
    private let clearTokens:      @Sendable () async -> Void
    private let refreshTarget:    @Sendable (String) -> any TargetType
    private let coordinator = RefreshCoordinator()

    init(
        loadAccessToken:  @escaping @Sendable () async -> String?,
        loadRefreshToken: @escaping @Sendable () async -> String?,
        saveTokens:       @escaping @Sendable (AuthTokens) async throws -> Void,
        clearTokens:      @escaping @Sendable () async -> Void,
        refreshTarget:    @escaping @Sendable (String) -> any TargetType
    ) {
        self.loadAccessToken  = loadAccessToken
        self.loadRefreshToken = loadRefreshToken
        self.saveTokens       = saveTokens
        self.clearTokens      = clearTokens
        self.refreshTarget    = refreshTarget
    }

    // Authorization 헤더 주입 (만료 임박 시 Proactive Refresh 포함)
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        Task {
            var request = urlRequest
            let requiresAuthorization = request.value(forHTTPHeaderField: NetworkManager.authorizationMarkerHeader) == "true"
            request.setValue(nil, forHTTPHeaderField: NetworkManager.authorizationMarkerHeader)

            if requiresAuthorization {
                // 만료 1분 전이면 미리 갱신
                if let token = await loadAccessToken(),
                   let expiry = decodeJWTExpiry(token),
                   expiry.timeIntervalSinceNow < 60 {
                    let isFirst = await coordinator.beginRefreshIfNeeded()
                    if isFirst {
                        if let refreshToken = await loadRefreshToken(),
                           let tokens = try? await fetchNewTokens(using: refreshToken) {
                            try? await saveTokens(tokens)
                        }
                        _ = await coordinator.finishRefresh(succeeded: true)
                    } else {
                        // 다른 요청이 이미 갱신 중 → 완료까지 대기
                        await coordinator.waitForRefresh()
                    }
                }
                if let token = await loadAccessToken() {
                    request.setValue(token, forHTTPHeaderField: "Authorization")
                }
            }
            NetworkManager.logIfNeeded(request)
            completion(.success(request))
        }
    }

    /// JWT payload의 exp 클레임을 Date로 디코딩
    private func decodeJWTExpiry(_ token: String) -> Date? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        var base64 = String(parts[1])
        let remainder = base64.count % 4
        if remainder != 0 { base64 += String(repeating: "=", count: 4 - remainder) }
        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else { return nil }
        return Date(timeIntervalSince1970: exp)
    }

    // 401 → 토큰 갱신 후 재시도
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard
            let statusCode = request.response?.statusCode,
            statusCode == 401,
            request.retryCount == 0
        else {
            completion(.doNotRetry)
            return
        }

        Task {
            let isFirst = await coordinator.beginRefreshIfNeeded()

            if !isFirst {
                // 이미 갱신 중 → 완료 후 같이 재시도
                await coordinator.enqueue(completion)
                return
            }

            do {
                guard let refreshToken = await loadRefreshToken() else {
                    throw NetworkError.unauthorized
                }
                let tokens = try await fetchNewTokens(using: refreshToken)
                try await saveTokens(tokens)

                let pending = await coordinator.finishRefresh(succeeded: true)
                completion(.retry)
                pending.forEach { $0(.retry) }
            } catch {
                await invalidateSession()
                let pending = await coordinator.finishRefresh(succeeded: false)
                completion(.doNotRetry)
                pending.forEach { $0(.doNotRetry) }
            }
        }
    }

    // 별도 URLSession으로 토큰 갱신 (인터셉터 재진입 방지)
    private func fetchNewTokens(using refreshToken: String) async throws -> AuthTokens {
        let target = refreshTarget(refreshToken)

        guard var components = URLComponents(string: target.baseURL + target.path),
              let url = components.url else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = target.method.rawValue
        target.headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        if case .json(let encodable) = target.body {
            urlRequest.httpBody = try JSONEncoder().encode(encodable)
        }

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw NetworkError.unauthorized
        }

        return try JSONDecoder().decode(RefreshTokenResponseDTO.self, from: data).tokens
    }

    private func invalidateSession() async {
        await clearTokens()
        NotificationCenter.default.post(name: Notification.Name("sessionDidInvalidate"), object: nil)
    }
}

// MARK: - RefreshCoordinator (동시 401 처리)

private actor RefreshCoordinator {
    private var isRefreshing = false
    private var pending: [(RetryResult) -> Void] = []
    /// adapt()의 proactive refresh 대기자 (async/await 기반)
    private var waiters: [CheckedContinuation<Void, Never>] = []

    /// true → 이 호출이 갱신을 시작해야 함, false → 대기열에 추가
    func beginRefreshIfNeeded() -> Bool {
        if isRefreshing { return false }
        isRefreshing = true
        return true
    }

    /// retry() 전용: completion 기반 대기
    func enqueue(_ completion: @escaping (RetryResult) -> Void) {
        pending.append(completion)
    }

    /// adapt() 전용: 갱신 완료까지 suspend
    func waitForRefresh() async {
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func finishRefresh(succeeded: Bool) -> [(RetryResult) -> Void] {
        isRefreshing = false
        let waiting = pending
        pending = []
        waiters.forEach { $0.resume() }
        waiters = []
        return waiting
    }
}

// MARK: - Private DTO

private struct ErrorResponseDTO: Decodable {
    let message: String
}
