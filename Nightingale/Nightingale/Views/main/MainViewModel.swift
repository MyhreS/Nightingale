import Foundation

private let defaultGroups: [SongGroup] = [
    "faceoff", "penalty", "goal", "crowd", "intro"
]

private let firebaseGroups: [SongGroup] = [
    "warmup", "faceoff", "break", "goal", "penalty", "crowd", "intro", "victory"
]

@MainActor
final class MainViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var availableGroups: [SongGroup] = defaultGroups
    @Published var isLoadingSongs = true
    @Published var errorWhenLoadingSongs = false
    @Published var hasFirebaseAccess = false

    func loadSongs(firebaseAPI: FirebaseAPI, email: String, scAuthenticated: Bool) async {
        isLoadingSongs = true
        errorWhenLoadingSongs = false
        defer { isLoadingSongs = false }

        do {
            try await FirebaseAuthGate.shared.ensureSignedIn()

            let localSongs = LocalSongStore.shared.allSongs()
            var serverSongs: [Song] = []

            let emailLower = email.lowercased()
            let allowedEmails = emailLower.isEmpty ? [] : try await firebaseAPI.fetchAllowedFirebaseSongsEmails()
            let emailIsAllowed = !emailLower.isEmpty && allowedEmails.contains(where: { $0.lowercased() == emailLower })

            if emailIsAllowed {
                let firebaseSongs = try await firebaseAPI.fetchFirebaseSongs()
                serverSongs = firebaseSongs
                hasFirebaseAccess = true
                startCacheWork(firebaseSongs: firebaseSongs)
            } else {
                hasFirebaseAccess = false
                if scAuthenticated {
                    serverSongs = try await firebaseAPI.fetchSoundcloudSongs()
                }
            }

            invalidateStaleArtwork(songs: serverSongs)
            songs = deduplicateById(serverSongs + localSongs)
            availableGroups = emailIsAllowed ? firebaseGroups : defaultGroups
        } catch {
            let localSongs = LocalSongStore.shared.allSongs()
            if !localSongs.isEmpty {
                songs = localSongs
            } else {
                errorWhenLoadingSongs = true
            }
            print("Failed to fetch songs: \(error)")
        }
    }

    func addLocalSong(from url: URL, group: SongGroup) async {
        guard let song = await LocalSongStore.shared.addSong(from: url, group: group) else { return }
        songs.append(song)
        if !availableGroups.contains(group) {
            availableGroups.append(group)
        }
    }

    func deleteLocalSong(_ song: Song) {
        LocalSongStore.shared.deleteSong(song)
        songs.removeAll { $0.songId == song.songId && $0.group == song.group }
    }

    func updateLocalSongStartTime(song: Song, startSeconds: Int) {
        LocalSongStore.shared.updateStartTime(songId: song.songId, startSeconds: startSeconds)
        if let index = songs.firstIndex(where: { $0.songId == song.songId && $0.group == song.group }) {
            songs[index].startSeconds = startSeconds
        }
    }

    func updateLocalSongName(song: Song, name: String) {
        LocalSongStore.shared.updateName(songId: song.songId, name: name)
        if let index = songs.firstIndex(where: { $0.songId == song.songId && $0.group == song.group }) {
            songs[index].name = name
        }
    }

    func updateLocalSongArtist(song: Song, artist: String) {
        LocalSongStore.shared.updateArtist(songId: song.songId, artist: artist)
        if let index = songs.firstIndex(where: { $0.songId == song.songId && $0.group == song.group }) {
            songs[index].artistName = artist
        }
    }

    private func invalidateStaleArtwork(songs: [Song]) {
        let key = "lastSeenUpdatedAt"
        let stored = UserDefaults.standard.dictionary(forKey: key) as? [String: Int] ?? [:]
        var updated = stored

        for song in songs {
            guard !song.artworkURL.isEmpty, let url = URL(string: song.artworkURL) else { continue }
            if let lastSeen = stored[song.songId], song.updatedAt > lastSeen {
                ImageCache.shared[url] = nil
            }
            updated[song.songId] = song.updatedAt
        }

        UserDefaults.standard.set(updated, forKey: key)
    }

    private func startCacheWork(firebaseSongs: [Song]) {
        Task {
            if firebaseSongs.isEmpty {
                await MP3Cache.shared.removeAllSongs()
            } else {
                await MP3Cache.shared.removeSongsNotInList(songs: firebaseSongs)
                await MP3Cache.shared.preloadSongs(songs: firebaseSongs)
            }
        }
    }
}

private func deduplicateById(_ songs: [Song]) -> [Song] {
    var seen = Set<String>()
    return songs.filter { song in
        guard !seen.contains(song.id) else { return false }
        seen.insert(song.id)
        return true
    }
}
