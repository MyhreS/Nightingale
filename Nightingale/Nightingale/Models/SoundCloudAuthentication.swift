import Foundation

final class SoundCloudAuthentication {
    static let shared = SoundCloudAuthentication()
    
    private var accessToken: String?
    private var tokenType: String?
    private var refreshToken: String?
    private var expiresAt: Date?
    
    private var isFetching = false
    private let fetchLock = NSLock()
    
    private let tokenURL = URL(string: "https://secure.soundcloud.com/oauth/token")!
    
    private lazy var clientID: String = {
        loadInfoValue("SOUND_CLOUD_CLIENT_ID")
    }()
    
    private lazy var clientSecret: String = {
        loadInfoValue("SOUND_CLOUD_CLIENT_SECRET")
    }()
    
    private init() {
        loadPersistedTokens()
        log("Loaded tokens: access=\(masked(accessToken)) expires=\(formatDate(expiresAt))")
    }
    
    func getValidAccessToken() async throws -> String {
        if isTokenValid() {
            log("Token is valid")
            return accessToken!
        }
        
        fetchLock.lock()
        if isFetching {
            fetchLock.unlock()
            try await Task.sleep(nanoseconds: 100_000_000)
            return try await getValidAccessToken()
        }
        isFetching = true
        fetchLock.unlock()
        
        defer {
            fetchLock.lock()
            isFetching = false
            fetchLock.unlock()
        }
        
        if shouldRefresh() {
            log("Refreshing token")
            try await refreshToken()
        } else {
            log("Fetching new client credentials token")
            try await fetchClientCredentialsToken()
        }
        
        guard let token = accessToken else {
            throw SoundCloudError.authenticationFailed("Failed to obtain access token")
        }
        
        return token
    }
    
    func getAuthorizationHeader() async throws -> String {
        let token = try await getValidAccessToken()
        return "Bearer \(token)"
    }
    
    func invalidateToken() {
        log("Invalidating token")
        accessToken = nil
        tokenType = nil
        expiresAt = nil
        KeychainStore.delete("sc_access_token")
        KeychainStore.delete("sc_token_type")
        KeychainStore.delete("sc_expires_at")
    }
}

private extension SoundCloudAuthentication {
    func isTokenValid() -> Bool {
        guard let token = accessToken, !token.isEmpty, let expiry = expiresAt else {
            return false
        }
        return Date() < expiry.addingTimeInterval(-60)
    }
    
    func shouldRefresh() -> Bool {
        guard let refresh = refreshToken, !refresh.isEmpty else {
            return false
        }
        guard let expiry = expiresAt else {
            return false
        }
        return Date() > expiry.addingTimeInterval(-60)
    }
    
    func loadInfoValue(_ key: String) -> String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            log("Missing Info.plist key: \(key)")
            return ""
        }
        return value
    }
    
    func loadPersistedTokens() {
        accessToken = KeychainStore.get("sc_access_token")
        tokenType = KeychainStore.get("sc_token_type")
        refreshToken = KeychainStore.get("sc_refresh_token")
        
        if let expiryString = KeychainStore.get("sc_expires_at"),
           let timestamp = TimeInterval(expiryString) {
            expiresAt = Date(timeIntervalSince1970: timestamp)
        }
    }
    
    func persistTokens(access: String, tokenType: String?, refresh: String?, expiresIn: Int) {
        self.accessToken = access
        self.tokenType = tokenType
        self.refreshToken = refresh
        self.expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        
        KeychainStore.set(access, for: "sc_access_token")
        if let type = tokenType {
            KeychainStore.set(type, for: "sc_token_type")
        }
        if let r = refresh {
            KeychainStore.set(r, for: "sc_refresh_token")
        }
        if let exp = expiresAt {
            KeychainStore.set(String(exp.timeIntervalSince1970), for: "sc_expires_at")
        }
        
        log("Persisted tokens: type=\(tokenType ?? "none") expires=\(formatDate(expiresAt))")
    }
    
    func fetchClientCredentialsToken() async throws {
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(makeBasicAuthHeader(), forHTTPHeaderField: "Authorization")
        req.httpBody = makeURLEncodedBody([
            URLQueryItem(name: "grant_type", value: "client_credentials")
        ])
        
        log("Fetching client credentials token")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw SoundCloudError.invalidResponse
        }
        
        log("Token response status: \(http.statusCode)")
        
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            log("Token error: \(body)")
            throw SoundCloudError.authenticationFailed("HTTP \(http.statusCode): \(body)")
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        persistTokens(
            access: tokenResponse.access_token,
            tokenType: tokenResponse.token_type,
            refresh: tokenResponse.refresh_token,
            expiresIn: tokenResponse.expires_in
        )
        
        log("Successfully obtained access token")
    }
    
    func refreshToken() async throws {
        guard let refresh = refreshToken, !refresh.isEmpty else {
            try await fetchClientCredentialsToken()
            return
        }
        
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.httpBody = makeURLEncodedBody([
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "refresh_token", value: refresh)
        ])
        
        log("Refreshing access token")
        
        let (data, response) = try await URLSession.shared.data(for: req)
        
        guard let http = response as? HTTPURLResponse else {
            throw SoundCloudError.invalidResponse
        }
        
        guard (200..<300).contains(http.statusCode) else {
            log("Refresh failed, fetching new token")
            try await fetchClientCredentialsToken()
            return
        }
        
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
        persistTokens(
            access: tokenResponse.access_token,
            tokenType: tokenResponse.token_type,
            refresh: tokenResponse.refresh_token,
            expiresIn: tokenResponse.expires_in
        )
        
        log("Successfully refreshed access token")
    }
    
    func makeBasicAuthHeader() -> String {
        let credentials = "\(clientID):\(clientSecret)"
        let data = credentials.data(using: .utf8) ?? Data()
        let base64 = data.base64EncodedString()
        return "Basic \(base64)"
    }
    
    func makeURLEncodedBody(_ items: [URLQueryItem]) -> Data? {
        var components = URLComponents()
        components.queryItems = items
        return components.percentEncodedQuery?.data(using: .utf8)
    }
    
    func masked(_ token: String?) -> String {
        guard let t = token, !t.isEmpty else { return "<none>" }
        let start = t.prefix(4)
        let end = t.suffix(2)
        return "\(start)...\(end)"
    }
    
    func formatDate(_ date: Date?) -> String {
        guard let d = date else { return "<nil>" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: d)
    }
    
    func log(_ message: String) {
        print("[SoundCloud Auth] \(message)")
    }
}

private extension SoundCloudAuthentication {
    struct TokenResponse: Decodable {
        let access_token: String
        let token_type: String?
        let refresh_token: String?
        let expires_in: Int
        let scope: String?
    }
}

