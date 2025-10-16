import Foundation

public final class SoundCloudAuth: ObservableObject {
    public static let shared = SoundCloudAuth()
    

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
    
    private init() {
        print(clientID)
        print(clientSecret)
    }

}


