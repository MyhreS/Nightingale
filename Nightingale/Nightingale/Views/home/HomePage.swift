import SwiftUI
import SoundCloud

struct HomePage: View {
    @EnvironmentObject var firebaseAPI: FirebaseAPI
    @StateObject private var player: MusicPlayer
    let songs: [PredefinedSong]
    @State private var selectedPreviewSong: PredefinedSong?
    @State private var selectedGroup: SongGroup = .faceoff
    @State private var playedTimeStamps: [String: Date] = [:]
    @State private var lastTapTime: Date?
    
    var filteredSongs: [PredefinedSong] {
        songs.filter { $0.group == selectedGroup }
    }
    
    var progressFraction: Double {
        let d = player.durationSeconds
        guard d > 0 else {return 0}
        return min(max(player.progressSeconds / d, 0), 1)
    }

    init(sc: SoundCloud) {
        _player = StateObject(wrappedValue: MusicPlayer(sc: sc))
        songs = PredefinedSongStore.loadPredefinedSongs()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PageLayout(title: "Music") {
                VStack(spacing: 16) {
                    SongGroupSelector(groups: SongGroup.allCases, selectedGroup: $selectedGroup)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredSongs) { song in
                                SongRow(
                                    song: song,
                                    isSelected: isSongSelected(song),
                                    isPlayed: isSongRecentlyPlayed(song),
                                    onTap: { handleSongTap(song) },
                                    onLongPress: { selectedPreviewSong = song }
                                )
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.bottom, 70)
                    }
                }
            }

            if let song = selectedPreviewSong {
                SongPreview(
                    song: song,
                    onClose: { selectedPreviewSong = nil }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }

            if player.currentSong != nil {
                MiniPlayerButton(
                    isPlaying: player.isPlaying,
                    progress: progressFraction,
                    action: { player.togglePlayPause() }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 100)
                .zIndex(900)
            }
        }
        .onAppear {
            player.onSongFinished = { finished in
                advanceToNextSong(after: finished)
            }
        }
        .onDisappear {
            player.onSongFinished = nil
        }
    }

    func handleSongTap(_ song: PredefinedSong) {

        player.play(song: song)
        playedTimeStamps[song.id] = Date()
    }
    
    func isSongSelected(_ song: PredefinedSong) -> Bool {
        if player.currentSong == song {
            return true
        }
        
        guard let lastPlayed = playedTimeStamps[song.id] else { return false }
        let interval = Date().timeIntervalSince(lastPlayed)
        return interval < 1.0
    }
    
    func isSongRecentlyPlayed(_ song: PredefinedSong) -> Bool {
        guard let lastPlayed = playedTimeStamps[song.id] else { return false }
        let interval = Date().timeIntervalSince(lastPlayed)
        return interval < 3 * 60 * 60
    }

    func advanceToNextSong(after song: PredefinedSong) {
        let groupSongs = songs.filter { $0.group == song.group }
        guard !groupSongs.isEmpty else { return }
        guard let index = groupSongs.firstIndex(of: song) else { return }

        let nextIndex = (index + 1) % groupSongs.count
        let nextSong = groupSongs[nextIndex]

        selectedGroup = song.group
        playedTimeStamps[nextSong.id] = Date()
        player.play(song: nextSong)
    }
}
