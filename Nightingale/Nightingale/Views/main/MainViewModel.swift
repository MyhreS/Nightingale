import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoadingSongs = false
    @Published var errorWhenLoadingSongs = false

    func loadSongs(firebaseAPI: FirebaseAPI, email: String, scAuthenticated: Bool) async {
        isLoadingSongs = true
        errorWhenLoadingSongs = false
        defer { isLoadingSongs = false }

        do {
            try await FirebaseAuthGate.shared.ensureSignedIn()

            var serverSongs: [Song] = []

            if scAuthenticated {
                let soundcloudSongs = try await firebaseAPI.fetchSoundcloudSongs()
                serverSongs.append(contentsOf: soundcloudSongs)
            }

            let emailLower = email.lowercased()
            let allowedEmails = emailLower.isEmpty ? [] : try await firebaseAPI.fetchAllowedFirebaseSongsEmails()

            if !emailLower.isEmpty && allowedEmails.contains(where: { $0.lowercased() == emailLower }) {
                let firebaseSongs = try await firebaseAPI.fetchFirebaseSongs()
                startCacheWork(firebaseSongs: firebaseSongs)

                let filtered = removeDuplicates(
                    soundcloudSongs: serverSongs,
                    firebaseSongs: firebaseSongs
                )
                serverSongs = firebaseSongs + filtered
            }

            let localSongs = LocalSongStore.shared.allSongs()
            songs = deduplicateById(serverSongs + localSongs)
            errorWhenLoadingSongs = songs.isEmpty
        } catch {
            let localSongs = LocalSongStore.shared.allSongs()
            if !localSongs.isEmpty {
                songs = localSongs
                errorWhenLoadingSongs = false
            } else {
                errorWhenLoadingSongs = true
            }
            print("Failed to fetch songs: \(error)")
        }
    }

    func addLocalSong(from url: URL, group: SongGroup) async {
        guard let song = await LocalSongStore.shared.addSong(from: url, group: group) else { return }
        songs.append(song)
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

func deduplicateById(_ songs: [Song]) -> [Song] {
    var seen = Set<String>()
    return songs.filter { song in
        guard !seen.contains(song.id) else { return false }
        seen.insert(song.id)
        return true
    }
}

func removeDuplicates(soundcloudSongs: [Song], firebaseSongs: [Song]) -> [Song] {
    let firebaseKeySet = Set(firebaseSongs.map(makeFirebaseSongKey))
    return soundcloudSongs.filter { !firebaseKeySet.contains(makeSoundcloudSongKey($0)) }
}

func makeSoundcloudSongKey(_ song: Song) -> String {
    "\(song.originalSongName.lowercased())|\(song.originalSongArtistName.lowercased())"
}

func makeFirebaseSongKey(_ song: Song) -> String {
    "\(song.name.lowercased())|\(song.artistName.lowercased())"
}
