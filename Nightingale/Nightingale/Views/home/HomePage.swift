import SwiftUI
import SoundCloud

struct HomePage: View {
    @StateObject private var player: MusicPlayer
    let songs: [PredefinedSong]
    @State private var selectedPreviewSong: PredefinedSong?
    @State private var selectedGroup: SongGroup = .goal
    
    var filteredSongs: [PredefinedSong] {
        songs.filter { $0.group == selectedGroup}
    }

    init(sc: SoundCloud) {
        _player = StateObject(wrappedValue: MusicPlayer(sc: sc))
        songs = PredefinedSongStore.loadPredefinedSongs()
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PageLayout(title: "Music") {
                VStack(spacing: 12) {
                    SongGroupSelector(groups: SongGroup.allCases, selectedGroup: $selectedGroup)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredSongs) { song in
                                SongRow(
                                    song: song,
                                    isSelected: player.currentSong == song,
                                    onTap: { handleSongTap(song) },
                                    onLongPress: { selectedPreviewSong = song }
                                )
                            }
                        }
                        .padding(.vertical, 4)
                        .padding(.bottom, 16)
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
                    action: { player.togglePlayPause() }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 80)
                .zIndex(900)
            }
        }
    }

    func handleSongTap(_ song: PredefinedSong) {
        player.play(song: song)
    }
}
