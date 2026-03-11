import Foundation

private let defaultGroups: [SongGroup] = [
    "intro", "faceoff", "penalty", "goal", "crowd"
]

private let firebaseGroups: [SongGroup] = [
    "warmup", "intro", "faceoff", "penalty", "goal", "crowd", "break", "victory"
]

private let preferredGroupOrder: [SongGroup] = [
    "warmup", "intro", "faceoff", "penalty", "goal", "crowd", "break", "victory"
]

// Toggle screenshot filler songs on/off before release.
private let screenshotModeAddsDummySongs = true

@MainActor
final class MainViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var availableGroups: [SongGroup] = defaultGroups
    @Published var isLoadingSongs = true
    @Published var errorWhenLoadingSongs = false
    @Published var hasFirebaseAccess = false
    private let remoteSongsCacheKey = "cachedRemoteSongs.v1"

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
            } else {
                hasFirebaseAccess = false
                if scAuthenticated {
                    serverSongs = try await firebaseAPI.fetchSoundcloudSongs()
                }
            }

            cacheRemoteSongs(serverSongs)
            invalidateStaleArtwork(songs: serverSongs)
            let merged = deduplicateById(serverSongs + localSongs)
            let groups = mergedGroups(
                base: emailIsAllowed ? firebaseGroups : defaultGroups,
                songs: merged
            )
            songs = screenshotModeAddsDummySongs ? addScreenshotDummySongs(to: merged, groups: groups) : merged
            availableGroups = groups
        } catch {
            let localSongs = LocalSongStore.shared.allSongs()
            let cachedRemote = cachedRemoteSongs()
            let merged = deduplicateById(cachedRemote + localSongs)

            if !merged.isEmpty {
                let hasCachedFirebase = merged.contains { $0.streamingSource == .firebase }
                hasFirebaseAccess = !email.isEmpty && hasCachedFirebase
                let groups = mergedGroups(
                    base: hasFirebaseAccess ? firebaseGroups : defaultGroups,
                    songs: merged
                )
                songs = screenshotModeAddsDummySongs ? addScreenshotDummySongs(to: merged, groups: groups) : merged
                availableGroups = groups
            } else {
                errorWhenLoadingSongs = true
                hasFirebaseAccess = false
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

    private func cacheRemoteSongs(_ songs: [Song]) {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        UserDefaults.standard.set(data, forKey: remoteSongsCacheKey)
    }

    private func cachedRemoteSongs() -> [Song] {
        guard let data = UserDefaults.standard.data(forKey: remoteSongsCacheKey),
              let decoded = try? JSONDecoder().decode([Song].self, from: data) else {
            return []
        }
        return decoded
    }

    private func mergedGroups(base: [SongGroup], songs: [Song]) -> [SongGroup] {
        var groups = base
        for group in songs.uniqueGroups where !groups.contains(group) {
            groups.append(group)
        }
        return sortGroups(groups)
    }

    private func sortGroups(_ groups: [SongGroup]) -> [SongGroup] {
        let rank = Dictionary(uniqueKeysWithValues: preferredGroupOrder.enumerated().map { ($1, $0) })
        return Array(Set(groups)).sorted { lhs, rhs in
            let lhsKey = lhs.lowercased() == "facoff" ? "faceoff" : lhs.lowercased()
            let rhsKey = rhs.lowercased() == "facoff" ? "faceoff" : rhs.lowercased()

            let lhsRank = rank[lhsKey] ?? Int.max
            let rhsRank = rank[rhsKey] ?? Int.max

            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
            return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }

    private func addScreenshotDummySongs(to songs: [Song], groups: [SongGroup]) -> [Song] {
        let targetCountPerGroup = 20
        var result = songs
        var usedIds = Set(result.map(\.id))

        for group in groups {
            let existingCount = result.filter { $0.group == group }.count
            guard existingCount < targetCountPerGroup else { continue }

            for index in existingCount..<targetCountPerGroup {
                let dummy = makeScreenshotDummySong(group: group, index: index)
                guard !usedIds.contains(dummy.id) else { continue }
                usedIds.insert(dummy.id)
                result.append(dummy)
            }
        }

        return result
    }

    private func makeScreenshotDummySong(group: SongGroup, index: Int) -> Song {
        let titles = [
            "Neon Breakaway", "Static Parade", "Turbo Lantern", "Polar Anthem", "Glass Velocity",
            "Afterglow", "Northstar", "Rushlight", "Nightfall", "Everwave",
            "Echo Harbor", "Signal Bloom", "Night Circuit", "Silver Rival", "Voltage Dream",
            "Laser Arcade", "Prism Takedown", "Midnight Sprint", "Nova Chant", "Frost Relay",
            "Pulse Theory", "Chrome Horizon", "Rocket Opera", "Shadow Jukebox", "Stellar Roar",
            "Midnight Over Center Ice", "Static Hearts in Bloom", "Racing Through the Floodlights",
            "Echoes From the Upper Deck", "Velvet Noise After Sundown", "Signals Under Northern Skies",
            "Bright Lights and Empty Streets", "Running Wild Through Winter", "The Last Chorus Tonight",
            "Shadows in a Golden Arcade"
        ]
        let artists = [
            "Auralite", "Velora", "Kintaro Kid", "Mosaic Youth", "Static Vale",
            "Luma Choir", "Pixel Motel", "North Arcade", "Saturn Twins", "Echo Season",
            "Glass Cast", "Mono Harbor", "Blue Static", "Nova Parade", "Cinder Club",
            "Fable Relay", "Jet Lagoon", "Silver Theory", "Prism Coast", "Night Foyer"
        ]

        return Song(
            songId: "screenshot-\(group)-\(index)",
            name: titles[index % titles.count],
            artistName: artists[(index + group.count) % artists.count],
            artworkURL: "",
            duration: 180_000,
            playbackUrl: "",
            linkToSong: "",
            linkToArtist: "",
            group: group,
            startSeconds: 0,
            streamingSource: .firebase,
            updatedAt: 0
        )
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
