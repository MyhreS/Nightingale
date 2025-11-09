import SwiftUI
import SoundCloud

struct HomePage: View {
    let sc: SoundCloud
    let songs = PredefinedSongStore.loadPredefinedSongs()
    
    var body: some View {
        PageLayout(title: "Music") {
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(songs) { song in
                        SongRow(song: song) {
                            handleSongTap(song)
                        }
                    }
                }
                .padding(.vertical, 4)
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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "play.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.orange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(song.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(song.id)
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
    }
}
