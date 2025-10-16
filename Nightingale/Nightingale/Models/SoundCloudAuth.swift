import Foundation
import CryptoKit
import AuthenticationServices
import UIKit

struct PKCE {
    let verifier: String
    let challenge: String

    static func generate() -> PKCE {
        let allowed = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let verifier = String((0..<64).compactMap { _ in allowed.randomElement() })
        let data = Data(verifier.utf8)
        let digest = SHA256.hash(data: data)
        let challenge = Data(digest).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return PKCE(verifier: verifier, challenge: challenge)
    }
}

func maskToken(token: String?) -> String {
    guard let t = token, !t.isEmpty else {return ""}
    let visible = t.prefix(4)
    let remaining = max(0, min(8, t.count - 4))
    return visible + String(repeating: "•", count: remaining)
}

public final class SoundCloudAuth: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
    public static let shared = SoundCloudAuth()

    @Published public private(set) var accessToken: String?
    @Published public private(set) var refreshToken: String?
    @Published public private(set) var expiresAt: Date?
    
    public var isAuthenticated: Bool {
        guard let token = accessToken, !token.isEmpty, let expiry = expiresAt else {return false}
        return Date() < expiry
    }

    var pendingPKCE: PKCE?
    var pendingState: String?

    private static var activeSession: ASWebAuthenticationSession?
    private static var isHandlingRedirect = false

    private override init() {
        super.init()
        if let a = KeychainStore.get("soundcloud_access_token") {
            accessToken = a
            print("[SoundCloudAuth] Loaded access token: \(maskToken(token: a))")
        }
        if let r = KeychainStore.get("soundcloud_refresh_token") {
            refreshToken = r
            print("[SoundCloudAuth] Loaded refresh token: \(maskToken(token: r))")
        }
        if let e = KeychainStore.get("soundcloud_expires_at"),
           let t = TimeInterval(e) {
            expiresAt = Date(timeIntervalSince1970: t)
            print("[SoundCloudAuth] Expires at \(Date(timeIntervalSince1970: t))")
        }
    }

    private static func loadInfoValue(_ key: String) -> String {
        let value = Bundle.main.object(forInfoDictionaryKey: key) as? String
        if let v = value, !v.isEmpty { return v }
        print("[SoundCloudAuth] Missing or empty Info.plist key: \(key)")
        return ""
    }

    public lazy var clientID: String = {
        let v = Self.loadInfoValue("SOUND_CLOUD_CLIENT_ID")
        print("[SoundCloudAuth] Loaded Client ID: \(v)")
        return v
    }()

    public lazy var clientSecret: String = {
        let v = Self.loadInfoValue("SOUND_CLOUD_CLIENT_SECRET")
        print("[SoundCloudAuth] Loaded Client Secret: \(maskToken(token: v))")
        return v
    }()

    public lazy var redirectURI: String = {
        let v = Self.loadInfoValue("REDIRECT_URI")
        print("[SoundCloudAuth] Loaded Redirect URI: \(v)")
        return v
    }()

    var authorizeBaseURL: URL { URL(string: "https://secure.soundcloud.com/authorize")! }
    var tokenURL: URL { URL(string: "https://secure.soundcloud.com/oauth/token")! }
    var meURL: URL { URL(string: "https://api.soundcloud.com/me")! }

    struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
        let expires_in: Int
        let scope: String?
        let token_type: String?
    }

    struct Me: Decodable {
        let id: Int
        let username: String?
    }

    func makeAuthorizeURL(codeChallenge: String, state: String) -> URL {
        var comps = URLComponents(url: authorizeBaseURL, resolvingAgainstBaseURL: false)!
        comps.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "display", value: "popup")
        ]
        return comps.url!
    }

    public func startAuthorizationWithASWebAuth() {
        let pkce = PKCE.generate()
        pendingPKCE = pkce
        let state = UUID().uuidString
        pendingState = state
        let url = makeAuthorizeURL(codeChallenge: pkce.challenge, state: state)
        let callbackScheme = URL(string: redirectURI)?.scheme
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { [weak self] callbackURL, error in
            guard let self else { return }
            if let url = callbackURL {
                self.handleRedirect(url: url)
            } else if let error {
                print("[SoundCloudAuth] ASWebAuthenticationSession canceled/failed: \(error.localizedDescription)")
            }
            Self.activeSession = nil
        }
        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false
        Self.activeSession = session
        session.start()
    }

    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    func handleRedirect(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = comps.queryItems else { return }
        let code = items.first(where: { $0.name == "code" })?.value
        let state = items.first(where: { $0.name == "state" })?.value
        guard let code, let state, state == pendingState else {
            print("[SoundCloudAuth] Missing or invalid code/state")
            return
        }
        if Self.isHandlingRedirect { return }
        Self.isHandlingRedirect = true
        Task {
            await exchangeCodeForToken(code: code)
            await MainActor.run { Self.isHandlingRedirect = false }
        }
    }

    @MainActor
    func exchangeCodeForToken(code: String) async {
        guard let verifier = pendingPKCE?.verifier else {
            print("[SoundCloudAuth] Missing PKCE verifier")
            pendingPKCE = nil
            pendingState = nil
            return
        }
        defer {
            pendingPKCE = nil
            pendingState = nil
        }
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        let bodyItems: [URLQueryItem] = [
            .init(name: "grant_type", value: "authorization_code"),
            .init(name: "client_id", value: clientID),
            .init(name: "client_secret", value: clientSecret),
            .init(name: "redirect_uri", value: redirectURI),
            .init(name: "code_verifier", value: verifier),
            .init(name: "code", value: code)
        ]
        req.httpBody = formURLEncodedBody(bodyItems)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("[SoundCloudAuth] Token exchange failed: \(resp)")
                if let s = String(data: data, encoding: .utf8) { print(s) }
                return
            }
            let token = try JSONDecoder().decode(TokenResponse.self, from: data)
            store(token: token)
            handleTokenReady()
        } catch {
            print("[SoundCloudAuth] Token exchange error: \(error)")
        }
    }

    @MainActor
    func refreshIfNeeded() async {
        guard let expiresAt else { return }
        if Date() > expiresAt.addingTimeInterval(-60) {
            await refreshAccessToken()
        }
    }

    @MainActor
    func refreshAccessToken() async {
        guard let refreshToken else { return }
        var req = URLRequest(url: tokenURL)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        let bodyItems: [URLQueryItem] = [
            .init(name: "grant_type", value: "refresh_token"),
            .init(name: "client_id", value: clientID),
            .init(name: "client_secret", value: clientSecret),
            .init(name: "refresh_token", value: refreshToken)
        ]
        req.httpBody = formURLEncodedBody(bodyItems)
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("[SoundCloudAuth] Refresh failed: \(resp)")
                if let s = String(data: data, encoding: .utf8) { print(s) }
                return
            }
            let token = try JSONDecoder().decode(TokenResponse.self, from: data)
            store(token: token)
            handleTokenReady()
        } catch {
            print("[SoundCloudAuth] Refresh error: \(error)")
        }
    }
}

private extension SoundCloudAuth {
    @MainActor
    func store(token: TokenResponse) {
        accessToken = token.access_token
        refreshToken = token.refresh_token
        expiresAt = Date().addingTimeInterval(TimeInterval(token.expires_in))

        KeychainStore.set(token.access_token, for: "soundcloud_access_token")
        if let r = token.refresh_token {
            KeychainStore.set(r, for: "soundcloud_refresh_token")
        }
        KeychainStore.set(String(expiresAt!.timeIntervalSince1970), for: "soundcloud_expires_at")
    }
    
    func formURLEncodedBody(_ items: [URLQueryItem]) -> Data? {
        var comps = URLComponents()
        comps.queryItems = items
        return comps.percentEncodedQuery?.data(using: .utf8)
    }

    func makeAuthedRequest(_ url: URL) -> URLRequest {
        var req = URLRequest(url: url)
        req.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        if let t = accessToken, !t.isEmpty {
            req.setValue("OAuth \(t)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    func maskedToken(_ token: String?) -> String {
        guard let t = token, !t.isEmpty else { return "<none>" }
        let start = t.prefix(6)
        let end = t.suffix(4)
        return "\(start)…\(end)"
    }

    func iso8601String(_ date: Date?) -> String {
        guard let d = date else { return "<unknown>" }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f.string(from: d)
    }

    @MainActor
    func printAuthState() {
        print("[SoundCloudAuth] Access token: \(maskedToken(accessToken))")
        print("[SoundCloudAuth] Expires at: \(iso8601String(expiresAt))")
    }

    @MainActor
    func handleTokenReady() {
        Task {
            await fetchCurrentUser()
            printAuthState()
        }
    }

    @MainActor
    func fetchCurrentUser() async {
        var req = makeAuthedRequest(meURL)
        req.httpMethod = "GET"
        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                print("[SoundCloudAuth] /me failed: \(resp)")
                if let s = String(data: data, encoding: .utf8) { print(s) }
                return
            }
            let me = try JSONDecoder().decode(Me.self, from: data)
            let username = me.username ?? "<nil>"
            print("[SoundCloudAuth] Authenticated as id=\(me.id) username=\(username)")
        } catch {
            print("[SoundCloudAuth] /me error: \(error)")
        }
    }
}
