import SwiftUI

struct SongRow: View {
    let song: PredefinedSong
    let isSelected: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HapticButton(action: onTap) {
            HStack(spacing: 12) {
                CachedAsyncImage(url: URL(string: song.artworkURL)) { image in
                    artworkView(for: image)
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

    private func artworkView(for image: Image?) -> some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.2))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.caption)
                            .foregroundStyle(.orange.opacity(0.6))
                    )
                    .redacted(reason: .placeholder)
            }
        }
    }
}
