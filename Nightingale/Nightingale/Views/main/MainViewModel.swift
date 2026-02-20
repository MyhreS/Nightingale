import Foundation

@MainActor
final class MainViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var availableGroups: [SongGroup] = []
    @Published var isLoadingSongs = false
    @Published var errorWhenLoadingSongs = false

    func loadSongs(firebaseAPI: FirebaseAPI, email: String, scAuthenticated: Bool) async {
        isLoadingSongs = true
        errorWhenLoadingSongs = false
        defer { isLoadingSongs = false }

        do {
            try await FirebaseAuthGate.shared.ensureSignedIn()

            let allFirebaseSongs = try await firebaseAPI.fetchFirebaseSongs()
            let allSoundcloudSongs = try await firebaseAPI.fetchSoundcloudSongs()
            let localSongs = LocalSongStore.shared.allSongs()

            availableGroups = (allFirebaseSongs + allSoundcloudSongs + localSongs).uniqueGroups

            var serverSongs: [Song] = []

            if scAuthenticated {
                serverSongs.append(contentsOf: allSoundcloudSongs)
            }

            let emailLower = email.lowercased()
            let allowedEmails = emailLower.isEmpty ? [] : try await firebaseAPI.fetchAllowedFirebaseSongsEmails()

            if !emailLower.isEmpty && allowedEmails.contains(where: { $0.lowercased() == emailLower }) {
                startCacheWork(firebaseSongs: allFirebaseSongs)

                let filtered = removeDuplicates(
                    soundcloudSongs: serverSongs,
                    firebaseSongs: allFirebaseSongs
                )
                serverSongs = allFirebaseSongs + filtered
            }

            songs = deduplicateById(serverSongs + localSongs)
            errorWhenLoadingSongs = songs.isEmpty && availableGroups.isEmpty
        } catch {
            let localSongs = LocalSongStore.shared.allSongs()
            if !localSongs.isEmpty {
                songs = localSongs
                availableGroups = localSongs.uniqueGroups
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
