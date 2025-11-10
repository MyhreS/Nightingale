import SwiftUI
import SoundCloud

struct HomePage: View {
    @StateObject private var player: MusicPlayer
    let songs: [PredefinedSong]
    @State private var selectedPreviewSong: PredefinedSong?
    @State private var selectedGroup: SongGroup = .goal
    @State private var playedTimeStamps: [String: Date] = [:]
    
    var filteredSongs: [PredefinedSong] {
        songs.filter { $0.group == selectedGroup }
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
                                    isSelected: player.currentSong == song,
                                    isPlayed: isSongRecentlyPlayed(song),
                                    onTap: { handleSongTap(song) },
                                    onLongPress: { selectedPreviewSong = song }
                                )
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.bottom, 20)
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
                    progress: player.progress,
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            playedTimeStamps[song.id] = Date()
        }
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
