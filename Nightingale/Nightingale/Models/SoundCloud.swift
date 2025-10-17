import Foundation

enum SoundCloud {
    private static let api = SoundCloudAPI.shared
    private static let auth = SoundCloudAuthentication.shared
    
    static func authenticate() async throws {
        _ = try await auth.getValidAccessToken()
    }
    
    static func search(query: String, limit: Int = 50) async throws -> [SCTrack] {
        try await api.search(query: query, limit: limit)
    }
    
    static func getTrack(url: String) async throws -> SCTrack {
        try await api.resolveURL(url)
    }
    
    static func getTrack(id: Int) async throws -> SCTrack {
        try await api.getTrack(id: id)
    }
}

