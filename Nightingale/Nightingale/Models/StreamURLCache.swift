import Foundation
import SoundCloud

struct CachedStreamURL {
    let url: URL
    let headers: [String: String]
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

@MainActor
final class StreamURLCache: ObservableObject {
    static let shared = StreamURLCache()
    
    private var cache: [String: CachedStreamURL] = [:]
    private let cacheExpirationMinutes: Double = 30
    
    private init() {}
    
    func getURL(for songId: String) -> CachedStreamURL? {
        guard let cached = cache[songId], !cached.isExpired else {
            if cache[songId] != nil {
                cache.removeValue(forKey: songId)
            }
            return nil
        }
        return cached
    }
    
    func setURL(for songId: String, url: URL, headers: [String: String]) {
        let expiresAt = Date().addingTimeInterval(cacheExpirationMinutes * 60)
        cache[songId] = CachedStreamURL(url: url, headers: headers, expiresAt: expiresAt)
    }
    
    func prefetchAll(songs: [PredefinedSong], using sc: SoundCloud) async {
        await withTaskGroup(of: (String, URL?, [String: String]?).self) { group in
            for song in songs {
                group.addTask {
                    do {
                        let streamInfo = try await sc.streamInfo(for: song.id)
                        let headers = try await sc.authorizationHeader
                        
                        if let url = URL(string: streamInfo.httpMp3128URL) ?? URL(string: streamInfo.hlsMp3128URL) {
                            return (song.id, url, headers)
                        }
                    } catch {
                        print("StreamURLCache: failed to prefetch \(song.name): \(error)")
                    }
                    return (song.id, nil, nil)
                }
            }
            
            for await (songId, url, headers) in group {
                if let url = url, let headers = headers {
                    setURL(for: songId, url: url, headers: headers)
                }
            }
        }
        print("StreamURLCache: prefetched \(cache.count) songs")
    }
    
    func clearCache() {
        cache.removeAll()
    }
}

