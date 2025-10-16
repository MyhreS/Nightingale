import Foundation

/// Represents an OAuth token received from SoundCloud.
public struct SoundCloudToken: Codable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresIn: Int?
    public let scope: String?
    public let createdAt: Date
    public let tokenType: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
        case createdAt = "created_at"
        case tokenType = "token_type"
    }

    public init(accessToken: String,
                refreshToken: String? = nil,
                expiresIn: Int? = nil,
                scope: String? = nil,
                createdAt: Date = Date(),
                tokenType: String? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.scope = scope
        self.createdAt = createdAt
        self.tokenType = tokenType
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try? container.decode(String.self, forKey: .refreshToken)
        expiresIn = try? container.decode(Int.self, forKey: .expiresIn)
        scope = try? container.decode(String.self, forKey: .scope)
        tokenType = try? container.decode(String.self, forKey: .tokenType)
        if let createdAtTimestamp = try? container.decode(TimeInterval.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
        } else {
            createdAt = Date()
        }
    }
}

/// Errors related to SoundCloud OAuth authorization flow.
public enum SoundCloudAuthError: Error {
    /// The redirect URL is invalid or unexpected.
    case invalidRedirect
    /// The authorization code is missing in the redirect URL.
    case missingCode
    /// There is no token available for authorized requests.
    case noToken
    /// The HTTP response returned an unexpected status code.
    case httpStatus(Int)
}

/// A final class managing SoundCloud OAuth authorization and API requests.
///
/// Usage:
/// 1. Start authorization by letting the user open `authorizationURL()` in a web browser or web view.
/// 2. When the user completes authorization, handle the redirect in your app's URL handler by calling `handleRedirect(_:)`.
/// 3. Exchange the received code for an OAuth token using `exchangeCodeForToken(_:)`.
/// 4. Use `perform(_:path:queryItems:)` to perform authorized API requests.
///
/// Example:
/// ```swift
/// let auth = SoundCloudAuth.shared
/// let url = auth.authorizationURL()
/// // Open `url` in a web view or externally.
/// ```
///
/// Handle redirect:
/// ```swift
/// func handleCallback(url: URL) async {
///     do {
///         let code = try await SoundCloudAuth.shared.handleRedirect(url)
///         let token = try await SoundCloudAuth.shared.exchangeCodeForToken(code)
///         print("Authorized with token: \(token.accessToken)")
///     } catch {
///         print("Authorization error: \(error)")
///     }
/// }
/// ```
public final class SoundCloudAuth: ObservableObject {
    public static let shared = SoundCloudAuth()
    private init() {}

    /// The currently stored OAuth token, if any.
    @Published public private(set) var token: SoundCloudToken?

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
        let masked = v.isEmpty ? "" : String(repeating: "•", count: max(4, min(12, v.count)))
        print("[SoundCloudAuth] Loaded Client Secret: \(masked)")
        return v
    }()

    public lazy var redirectURI: String = {
        let v = Self.loadInfoValue("REDIRECT_URI")
        print("[SoundCloudAuth] Loaded Redirect URI: \(v)")
        return v
    }()

    private let baseURL = URL(string: "https://api.soundcloud.com")!
    private let connectURL = URL(string: "https://soundcloud.com/connect")!

}


