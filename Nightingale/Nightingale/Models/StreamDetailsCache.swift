import Foundation
import SoundCloud

struct CachedStreamDetails {
    let url: URL
    let headers: [String: String]
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() >= expiresAt
    }
}

actor StreamDetailsCache {
    private var cache: [String: CachedStreamDetails] = [:]
    private let sc: SoundCloud
    private let firebaseAPI: FirebaseAPI
    private let expirationInterval: TimeInterval = 50 * 60
    
    init(sc: SoundCloud, firebaseAPI: FirebaseAPI) {
        self.sc = sc
        self.firebaseAPI = firebaseAPI
    }
    
    func preload(songs: [Song]) async {
        await withTaskGroup(of: Void.self) { group in
            for song in songs {
                group.addTask { [self] in
                    do {
                        _ = try await self.fetchAndCache(song: song)
                    } catch {
                        print("Failed to preload stream for \(song.name): \(error)")
                    }
                }
            }
        }
    }
    
    func getStreamDetails(for song: Song) async throws -> StreamDetails {
        if let cached = cache[song.id], !cached.isExpired {
            return StreamDetails(url: cached.url, headers: cached.headers)
        }
        
        return try await fetchAndCache(song: song)
    }
    
    private func fetchAndCache(song: Song) async throws -> StreamDetails {
        let details = try await fetchStreamDetails(song: song)
        let finalURL = await resolveRedirectedURL(url: details.url, headers: details.headers)
        
        let cached = CachedStreamDetails(
            url: finalURL,
            headers: details.headers,
            expiresAt: Date().addingTimeInterval(expirationInterval)
        )
        cache[song.id] = cached
        
        return StreamDetails(url: finalURL, headers: details.headers)
    }
    
    private func fetchStreamDetails(song: Song) async throws -> StreamDetails {
        switch song.streamingSource {
        case .soundcloud:
            let streamInfo = try await sc.streamInfo(for: song.songId)
            let headers = try await sc.authorizationHeader
            
            guard let url = URL(string: streamInfo.httpMp3128URL) ?? URL(string: streamInfo.hlsMp3128URL) else {
                throw URLError(.badURL)
            }
            return StreamDetails(url: url, headers: headers)
            
        case .firebase:
            let url = try await firebaseAPI.fetchStorageDownloadURL(path: song.songId)
            return StreamDetails(url: url, headers: [:])
        }
    }
    
    private func resolveRedirectedURL(url: URL, headers: [String: String]) async -> URL {
        final class RedirectCatcher: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
            private let lock = NSLock()
            private var redirectedURLStorage: URL?

            func urlSession(
                _ session: URLSession,
                task: URLSessionTask,
                willPerformHTTPRedirection response: HTTPURLResponse,
                newRequest request: URLRequest,
                completionHandler: @escaping (URLRequest?) -> Void
            ) {
                setRedirectedURL(request.url)
                completionHandler(nil)
            }

            func setRedirectedURL(_ url: URL?) {
                lock.lock()
                redirectedURLStorage = url
                lock.unlock()
            }

            func redirectedURL() -> URL? {
                lock.lock()
                let url = redirectedURLStorage
                lock.unlock()
                return url
            }
        }

        let delegate = RedirectCatcher()
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)

        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }

        do {
            _ = try await session.data(for: req)
        } catch {
            // Redirect was caught and cancelled - this is expected
        }

        if let redirected = delegate.redirectedURL() {
            return redirected
        }

        return url
    }
    
    func refreshExpiredEntries(songs: [Song]) async {
        let expiredSongs = songs.filter { song in
            guard let cached = cache[song.id] else { return true }
            return cached.isExpired
        }
        
        guard !expiredSongs.isEmpty else { return }
        await preload(songs: expiredSongs)
    }
}

