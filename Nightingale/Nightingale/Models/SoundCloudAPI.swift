import Foundation

enum SoundCloudError: Error, LocalizedError {
    case authenticationFailed(String)
    case invalidResponse
    case httpError(Int, String)
    case invalidURL
    case decodingError(Error)
    case notFound
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code, let message):
            return "HTTP \(code): \(message)"
        case .invalidURL:
            return "Invalid URL"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Rate limit exceeded"
        }
    }
}

struct SCUser: Decodable {
    let id: Int
    let username: String
    let avatar_url: String?
    let permalink_url: String
}

struct SCTrack: Decodable {
    let id: Int
    let title: String
    let duration: Int
    let genre: String?
    let artwork_url: String?
    let permalink_url: String
    let user: SCUser
    let description: String?
    let playback_count: Int?
    let likes_count: Int?
    let created_at: String?
}

struct SCSearchResponse: Decodable {
    let collection: [SCTrack]
    let next_href: String?
}

struct SCResolveResponse: Decodable {
    let location: String
}

final class SoundCloudAPI {
    static let shared = SoundCloudAPI()
    
    private let baseURL = "https://api.soundcloud.com"
    private let auth = SoundCloudAuthentication.shared
    
    private init() {}
    
    func search(query: String, limit: Int = 50) async throws -> [SCTrack] {
        var components = URLComponents(string: "\(baseURL)/tracks")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "linked_partitioning", value: "true")
        ]
        
        guard let url = components.url else {
            throw SoundCloudError.invalidURL
        }
        
        log("Searching tracks: query=\(query) limit=\(limit)")
        
        let data = try await performRequest(url: url)
        
        do {
            let response = try JSONDecoder().decode(SCSearchResponse.self, from: data)
            log("Found \(response.collection.count) tracks")
            return response.collection
        } catch {
            throw SoundCloudError.decodingError(error)
        }
    }
    
    func getTrack(id: Int) async throws -> SCTrack {
        guard let url = URL(string: "\(baseURL)/tracks/\(id)") else {
            throw SoundCloudError.invalidURL
        }
        
        log("Fetching track: id=\(id)")
        
        let data = try await performRequest(url: url)
        
        do {
            return try JSONDecoder().decode(SCTrack.self, from: data)
        } catch {
            throw SoundCloudError.decodingError(error)
        }
    }
    
    func resolveURL(_ urlString: String) async throws -> SCTrack {
        var components = URLComponents(string: "\(baseURL)/resolve")!
        components.queryItems = [
            URLQueryItem(name: "url", value: urlString)
        ]
        
        guard let url = components.url else {
            throw SoundCloudError.invalidURL
        }
        
        log("Resolving URL: \(urlString)")
        
        let data = try await performRequest(url: url)
        
        if let track = try? JSONDecoder().decode(SCTrack.self, from: data) {
            log("Resolved directly to track: \(track.title)")
            return track
        }
        
        if let resolveResponse = try? JSONDecoder().decode(SCResolveResponse.self, from: data),
           let redirectURL = URL(string: resolveResponse.location) {
            log("Following redirect to: \(resolveResponse.location)")
            let redirectData = try await performRequest(url: redirectURL)
            do {
                return try JSONDecoder().decode(SCTrack.self, from: redirectData)
            } catch {
                throw SoundCloudError.decodingError(error)
            }
        }
        
        throw SoundCloudError.decodingError(NSError(domain: "SoundCloudAPI", code: -1, userInfo: [NSLocalizedDescriptionKey: "Could not decode track from response"]))
    }
    
    private func performRequest(url: URL, retry: Bool = true) async throws -> Data {
        let authHeader = try await auth.getAuthorizationHeader()
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Accept")
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw SoundCloudError.invalidResponse
        }
        
        log("Response status: \(http.statusCode)")
        
        switch http.statusCode {
        case 200..<300:
            return data
            
        case 401:
            if retry {
                log("Got 401, invalidating token and retrying")
                auth.invalidateToken()
                return try await performRequest(url: url, retry: false)
            } else {
                let body = String(data: data, encoding: .utf8) ?? "No response body"
                throw SoundCloudError.httpError(401, body)
            }
            
        case 404:
            throw SoundCloudError.notFound
            
        case 429:
            throw SoundCloudError.rateLimited
            
        default:
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            log("Error response: \(body)")
            throw SoundCloudError.httpError(http.statusCode, body)
        }
    }
    
    private func log(_ message: String) {
        print("[SoundCloud API] \(message)")
    }
}

enum TrackPrinter {
    static func printSummary(for track: SCTrack) {
        let mins = track.duration / 1000 / 60
        let secs = track.duration / 1000 % 60
        let duration = String(format: "%d:%02d", mins, secs)
        
        print("""
        🎵 \(track.title)
        👤 \(track.user.username)
        ⏱ \(duration)
        🎧 Genre: \(track.genre ?? "-")
        🌐 \(track.permalink_url)
        """)
    }
}
