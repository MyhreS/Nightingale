import Foundation

public final class SoundCloudAppAuth: NSObject, ObservableObject {
    public static let shared = SoundCloudAppAuth()
    
    @Published public private(set) var accessToken: String?
    @Published public private(set) var refreshToken: String?
    @Published public private(set) var expiresAt: Date?
    
    private static var isFetching = false
    
    private override init() {
        super.init()
        log("init")
        loadPersistedTokens()
        log("loaded persisted tokens access=\(masked(accessToken)) refresh=\(masked(refreshToken)) expires=\(iso8601(expiresAt))")
    }
    
    public var isAuthorized: Bool {
        guard let token = accessToken, !token.isEmpty, let expiry = expiresAt else { return false }
        return Date() < expiry
    }
    
    public var tokenURL: URL { URL(string: "https://secure.soundcloud.com/oauth/token")! }
    
    public lazy var clientID: String = {
        let v = Self.loadInfoValue("SOUND_CLOUD_CLIENT_ID")
        log("clientID loaded \(v.isEmpty ? "<empty>" : "****")")
        return v
    }()
    
    public lazy var clientSecret: String = {
        let v = Self.loadInfoValue("SOUND_CLOUD_CLIENT_SECRET")
        log("clientSecret loaded \(v.isEmpty ? "<empty>" : "****")")
        return v
    }()
    
    public func ensureValidToken() async {
        log("ensureValidToken start authorized=\(isAuthorized) expires=\(iso8601(expiresAt))")
        if await shouldRefresh() {
            log("ensureValidToken refreshing")
            await refreshAppToken()
        } else if !isAuthorized {
            log("ensureValidToken fetching client_credentials")
            await fetchClientCredentialsToken()
        } else {
            log("ensureValidToken ok")
        }
    }
    
    public func bearerAuthorizationHeader() async -> String? {
        await ensureValidToken()
        guard let t = accessToken, !t.isEmpty else {
            log("bearerAuthorizationHeader missing token")
            return nil
        }
        log("bearerAuthorizationHeader ready")
        return "Bearer \(t)"
    }
    
    public func makeAuthedRequest(_ url: URL) async -> URLRequest {
        log("makeAuthedRequest \(url.absoluteString)")
        var req = URLRequest(url: url)
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        if let auth = await bearerAuthorizationHeader() {
            req.setValue(auth, forHTTPHeaderField: "Authorization")
            log("makeAuthedRequest set Authorization")
        } else {
            log("makeAuthedRequest no Authorization")
        }
        return req
    }
}

private extension SoundCloudAppAuth {
    static func loadInfoValue(_ key: String) -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        if let v = value, !v.isEmpty { return v }
        print("[SCAppAuth] Missing or empty Info.plist key: \(key)")
        return ""
    }
    
    func loadPersistedTokens() {
        if let a = KeychainStore.get("sc_app_access_token") { accessToken = a }
        if let r = KeychainStore.get("sc_app_refresh_token") { refreshToken = r }
        if let e = KeychainStore.get("sc_app_expires_at"), let t = TimeInterval(e) { expiresAt = Date(timeIntervalSince1970: t) }
    }
    
    func persistTokens(access: String, refresh: String?, expiresIn: Int) {
        accessToken = access
        refreshToken = refresh
        expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        KeychainStore.set(access, for: "sc_app_access_token")
        if let r = refresh { KeychainStore.set(r, for: "sc_app_refresh_token") }
        if let exp = expiresAt { KeychainStore.set(String(exp.timeIntervalSince1970), for: "sc_app_expires_at") }
        log("persistTokens access=\(masked(accessToken)) refresh=\(masked(refreshToken)) expires=\(iso8601(expiresAt)) ttl=\(expiresIn)s")
    }
    
    func shouldRefresh() async -> Bool {
        guard let expiry = expiresAt else {
            log("shouldRefresh no expiry")
            return false
        }
        let will = Date() > expiry.addingTimeInterval(-60)
        log("shouldRefresh \(will) now=\(iso8601(Date())) expiry=\(iso8601(expiry))")
        return will
    }
    
    func basicAuthHeader() -> String {
        let raw = "\(clientID):\(clientSecret)"
        let data = raw.data(using: .utf8) ?? Data()
        let b64 = data.base64EncodedString()
        log("basicAuthHeader built")
        return "Basic \(b64)"
    }
    
    func urlEncodedBody(_ items: [URLQueryItem]) -> Data? {
        var comps = URLComponents()
        comps.queryItems = items
        let body = comps.percentEncodedQuery?.data(using: .utf8)
        log("urlEncodedBody \(items.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&"))")
        return body
    }
    
    func masked(_ token: String?) -> String {
        guard let t = token, !t.isEmpty else { return "<none>" }
        let start = t.prefix(4)
        let end = t.suffix(2)
        return "\(start)…\(end)"
    }
    
    func iso8601(_ date: Date?) -> String {
        guard let d = date else { return "<nil>" }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: d)
    }
    
    func log(_ msg: String) {
        print("[SCAppAuth] \(msg)")
    }
}

private extension SoundCloudAppAuth {
    struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
        let expires_in: Int
        let scope: String?
        let token_type: String?
    }
    
    @MainActor
    func applyTokenResponse(_ token: TokenResponse) {
        log("applyTokenResponse start")
        persistTokens(access: token.access_token, refresh: token.refresh_token, expiresIn: token.expires_in)
        log("applyTokenResponse done")
    }
    
    func fetchClientCredentialsToken() async {
        if Self.isFetching {
            log("fetchClientCredentialsToken already fetching")
            return
        }
        Self.isFetching = true
        defer { Self.isFetching = false }
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue(basicAuthHeader(), forHTTPHeaderField: "Authorization")
        let body: [URLQueryItem] = [.init(name: "grant_type", value: "client_credentials")]
        req.httpBody = urlEncodedBody(body)
        log("fetchClientCredentialsToken request \(tokenURL.absoluteString)")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                log("fetchClientCredentialsToken invalid response")
                return
            }
            log("fetchClientCredentialsToken status \(http.statusCode)")
            guard (200..<300).contains(http.statusCode) else {
                if let s = String(data: data, encoding: .utf8) { log("fetchClientCredentialsToken body \(s)") }
                return
            }
            let token = try JSONDecoder().decode(TokenResponse.self, from: data)
            await applyTokenResponse(token)
            log("fetchClientCredentialsToken success")
        } catch {
            log("fetchClientCredentialsToken error \(error.localizedDescription)")
        }
    }
    
    func refreshAppToken() async {
        guard let r = refreshToken, !r.isEmpty else {
            log("refreshAppToken missing refreshToken, fetching new client_credentials")
            await fetchClientCredentialsToken()
            return
        }
        if Self.isFetching {
            log("refreshAppToken already fetching")
            return
        }
        Self.isFetching = true
        defer { Self.isFetching = false }
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        let body: [URLQueryItem] = [
            .init(name: "grant_type", value: "refresh_token"),
            .init(name: "client_id", value: clientID),
            .init(name: "client_secret", value: clientSecret),
            .init(name: "refresh_token", value: r)
        ]
        req.httpBody = urlEncodedBody(body)
        log("refreshAppToken request \(tokenURL.absoluteString)")
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                log("refreshAppToken invalid response")
                await fetchClientCredentialsToken()
                return
            }
            log("refreshAppToken status \(http.statusCode)")
            guard (200..<300).contains(http.statusCode) else {
                if let s = String(data: data, encoding: .utf8) { log("refreshAppToken body \(s)") }
                await fetchClientCredentialsToken()
                return
            }
            let token = try JSONDecoder().decode(TokenResponse.self, from: data)
            await applyTokenResponse(token)
            log("refreshAppToken success")
        } catch {
            log("refreshAppToken error \(error.localizedDescription)")
            await fetchClientCredentialsToken()
        }
    }
}
