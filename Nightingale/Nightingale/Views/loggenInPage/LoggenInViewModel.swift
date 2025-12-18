import Foundation
import SoundCloud

@MainActor
final class LoggedInViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoadingSongs = false
    @Published var errorWhenLoadingSongs = false

    func loadSongs(firebaseAPI: FirebaseAPI, user: User) async {
        isLoadingSongs = true
        errorWhenLoadingSongs = false
        defer { isLoadingSongs = false }

        do {
            let soundcloudSongs = try await firebaseAPI.fetchSoundcloudSongs()
            let users = try await firebaseAPI.fetchUsersAllowedFirebaseSongs()

            guard users.contains(extractSoundCloudUserId(userId: user.id)) else {
                songs = deduplicateById(soundcloudSongs)
                errorWhenLoadingSongs = songs.isEmpty
                return
            }

            let firebaseSongs = try await firebaseAPI.fetchFirebaseSongs()
            startCacheWork(firebaseSongs: firebaseSongs)

            let filteredSoundcloudSongs = removeDuplicates(
                soundcloudSongs: soundcloudSongs,
                firebaseSongs: firebaseSongs
            )

            songs = deduplicateById(firebaseSongs + filteredSoundcloudSongs)
            errorWhenLoadingSongs = songs.isEmpty
        } catch {
            errorWhenLoadingSongs = true
            print("Failed to fetch songs: \(error)")
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
    let firebaseKeySet = Set(firebaseSongs.map(makeSongKey))
    return soundcloudSongs.filter { !firebaseKeySet.contains(makeSongKey($0)) }
}

func makeSongKey(_ song: Song) -> String {
    "\(song.name.lowercased())|\(song.artistName.lowercased())"
}
