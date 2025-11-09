import SwiftUI
import SoundCloud

struct HomePage: View {
    let sc: SoundCloud
    let songs = PredefinedSongStore.loadPredefinedSongs()
    @State private var selectedSong: PredefinedSong?

    var body: some View {
        ZStack {
            PageLayout(title: "Music") {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(songs) { song in
                            SongRow(
                                song: song,
                                onTap: { handleSongTap(song) },
                                onLongPress: { selectedSong = song }
                            )
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            
            if let song = selectedSong {
                SongDetailOverlay(
                    song: song,
                    onClose: { selectedSong = nil }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }
        }
    }
    
    func handleSongTap(_ song: PredefinedSong) {
        print("Not implemented: \(song.name) (\(song.id))")
    }
}

struct SongRow: View {
    let song: PredefinedSong
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    .fill(Color(.secondarySystemBackground))
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
                        Button {
                            onPlay()
                        } label: {
                            Label("Play (not implemented)", systemImage: "play.fill")
                                .font(.subheadline)
                        }
                        
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
