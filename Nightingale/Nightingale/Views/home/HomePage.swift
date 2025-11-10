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
                SongDetailOverlay(
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

struct SongRow: View {
    let song: PredefinedSong
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HapticButton(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: URL(string: song.artworkURL)) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.2))
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("by \(song.artistName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.orange.opacity(0.2) : Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            LongPressGesture().onEnded { _ in
                onLongPress()
            }
        )
    }
}

struct SongDetailOverlay: View {
    let song: PredefinedSong
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            VStack(spacing: 20) {
                    AsyncImage(url: URL(string: song.artworkURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.2))
                    }
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    VStack(spacing: 6) {
                        Text(song.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("by \(song.artistName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        if let songUrl = URL(string: song.linkToSong) {
                            Link(destination: songUrl) {
                                Label("Open song on SoundCloud", systemImage: "music.note")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let artistUrl = URL(string: song.linkToArtist) {
                            Link(destination: artistUrl) {
                                Label("Open artist on SoundCloud", systemImage: "person.fill")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .frame(maxWidth: 320)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 16)
        }
    }
    
    var formattedDuration: String {
        let totalSeconds = song.duration / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func onPlay() {
        print("Not implemented: \(song.name) (\(song.id))")
    }
}

struct MiniPlayerButton: View {
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 30, weight: .bold))
                .padding(26)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(radius: 8)
        }
        .buttonStyle(.plain)
    }
}
