import Foundation

final class MP3Cache {
    private let firebaseAPI: FirebaseAPI
    let baseURL: URL
    
    @MainActor
    static let shared = MP3Cache(firebaseAPI: .shared)

    init(firebaseAPI: FirebaseAPI) {
        self.firebaseAPI = firebaseAPI
        self.baseURL = MP3Cache.makeBaseURL()
    }
    
    func removeAllSongs() async {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
                )
            
            for url in fileURLs {
                guard url.pathExtension.lowercased() == "mp3" else { continue }
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            return
        }
    }
    
    func removeSongsNotInList(songs: [Song]) async {
        let allowedFileNames = Set(
            songs.map { safeFileName(from: $0.songId) }
        )

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            for url in fileURLs {
                guard url.pathExtension.lowercased() == "mp3" else { continue }

                let fileName = url.lastPathComponent
                if !allowedFileNames.contains(fileName) {
                    try FileManager.default.removeItem(at: url)
                }
            }
        } catch {
            return
        }
    }
    
    func preloadSongs(songs: [Song]) async {
        let uncachedSongs = songs.filter{ song in
            let localURL = getPreloadedSongPath(song: song)
            return !isCached(at: localURL)
        }
        
        await withTaskGroup(of: Void.self) { group in
            for song in uncachedSongs {
                group.addTask {
                    do {
                        let localURL = self.getPreloadedSongPath(song: song)
                        _ = try await self.downloadMP3(from: song.songId, to: localURL)
                    }
                    catch {
                        return
                    }
                }
            }
            await group.waitForAll()
            
        }
    }
    
    func cachedURL(for song: Song) -> URL {
        getPreloadedSongPath(song: song)
    }
    
    func hasCachedSong(_ song: Song) -> Bool {
        isCached(at: cachedURL(for: song))
    }
    
    private func getPreloadedSongPath(song: Song) -> URL {
        baseURL.appendingPathComponent(safeFileName(from: song.songId), isDirectory: false)
    }
    
    private func safeFileName(from storagePath: String) -> String {
        let sanitized = storagePath.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ":", with: "_")
        return sanitized.hasSuffix(".mp3") ? sanitized : "\(sanitized).mp3"
    }
    
    
    private static func makeBaseURL() -> URL {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        
        return (caches.first ?? FileManager.default.temporaryDirectory).appendingPathComponent("mp3-cache", isDirectory: true)
    }
    
    private func isCached(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    private func store(tempURL: URL, at destinationURL: URL) throws {
        try createDirectoryIfNeeded(for: destinationURL)

        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: tempURL)
            return
        }
        
        do {
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
        } catch {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: tempURL)
                return
            }
            throw error
        }

    }

    private func createDirectoryIfNeeded(for fileURL: URL) throws {
        let dir = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    
    func downloadMP3(from storagePath: String, to localURL: URL) async throws -> URL {
        let remoteURL = try await firebaseAPI.fetchStorageDownloadURL(path: storagePath)
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
        try store(tempURL: tempURL, at: localURL)
        return localURL
    }
}
