import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var availableGroups: [SongGroup] = [
        "warmup", "faceoff", "break", "goal", "penalty", "crowd", "intro", "victory"
    ]
    @Published var isLoadingSongs = false
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

            songs = deduplicateById(serverSongs + localSongs)
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
            songs[index].originalSongName = ""
        }
    }

    func updateLocalSongArtist(song: Song, artist: String) {
        LocalSongStore.shared.updateArtist(songId: song.songId, artist: artist)
        if let index = songs.firstIndex(where: { $0.songId == song.songId && $0.group == song.group }) {
            songs[index].artistName = artist
            songs[index].originalSongArtistName = ""
        }
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
