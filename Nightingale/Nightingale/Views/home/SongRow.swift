import SwiftUI

struct SongRow: View {
    let song: PredefinedSong
    let isSelected: Bool
    let isPlayed: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
        HapticButton(action: onTap) {
            HStack(spacing: 14) {
                CachedAsyncImage(url: URL(string: song.artworkURL)) { image in
                    artworkView(for: image)
                }
                .frame(width: 52, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(song.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("by \(song.artistName)")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer(minLength: 12)
                
                if isPlayed {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 10, height: 10)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 68)
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
                    .fill(Color.orange.opacity(0.15))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 18))
                            .foregroundStyle(.orange.opacity(0.5))
                    )
                    .redacted(reason: .placeholder)
            }
        }
    }
}
