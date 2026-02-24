import Foundation

final class MP3Cache {
    private let firebaseAPI: FirebaseAPI
    let baseURL: URL
    private let metaURL: URL
    
    @MainActor
    static let shared = MP3Cache(firebaseAPI: .shared)

    init(firebaseAPI: FirebaseAPI) {
        self.firebaseAPI = firebaseAPI
        self.baseURL = MP3Cache.makeBaseURL()
        self.metaURL = baseURL.appendingPathComponent("cache-meta.json", isDirectory: false)
    }

    // MARK: - Sidecar metadata (songId -> updatedAt)

    private func loadMeta() -> [String: Int] {
        guard let data = try? Data(contentsOf: metaURL),
              let dict = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        return dict
    }

    private func saveMeta(_ meta: [String: Int]) {
        guard let data = try? JSONEncoder().encode(meta) else { return }
        try? createDirectoryIfNeeded(for: metaURL)
        try? data.write(to: metaURL, options: .atomic)
    }

    // MARK: - Public API
    
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
        saveMeta([:])
    }
    
    func removeSongsNotInList(songs: [Song]) async {
        let allowedFileNames = Set(
            songs.map { safeFileName(from: $0.songId) }
        )
        let allowedIds = Set(songs.map(\.songId))

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

        var meta = loadMeta()
        meta = meta.filter { allowedIds.contains($0.key) }
        saveMeta(meta)
    }
    
    func preloadSongs(songs: [Song]) async {
        let meta = loadMeta()

        let songsToDownload = songs.filter { song in
            guard song.streamingSource == .firebase else { return false }
            let localURL = getPreloadedSongPath(song: song)
            if !isCached(at: localURL) { return true }
            return meta[song.songId] != song.updatedAt
        }
        
        guard !songsToDownload.isEmpty else { return }

        await withTaskGroup(of: (String, Int)?.self) { group in
            for song in songsToDownload {
                group.addTask {
                    do {
                        let localURL = self.getPreloadedSongPath(song: song)
                        if self.isCached(at: localURL) {
                            try FileManager.default.removeItem(at: localURL)
                        }
                        _ = try await self.downloadMP3(from: song.songId, to: localURL)
                        return (song.songId, song.updatedAt)
                    } catch {
                        return nil
                    }
                }
            }

            var updatedMeta = loadMeta()
            for await result in group {
                guard let (songId, updatedAt) = result else { continue }
                updatedMeta[songId] = updatedAt
            }
            saveMeta(updatedMeta)
        }
    }
    
    func cachedURL(for song: Song) -> URL {
        getPreloadedSongPath(song: song)
    }
    
    func hasCachedSong(_ song: Song) -> Bool {
        let localURL = cachedURL(for: song)
        guard isCached(at: localURL) else { return false }
        let meta = loadMeta()
        return meta[song.songId] == song.updatedAt
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
            try FileManager.default.removeItem(at: destinationURL)
        }

        try FileManager.default.moveItem(at: tempURL, to: destinationURL)
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
