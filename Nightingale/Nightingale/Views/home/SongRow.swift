import SwiftUI

struct SongRow: View {
    let song: PredefinedSong
    let isSelected: Bool
    let isPlayed: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    
    var body: some View {
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
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
        .background(
            isSelected ? 
                Color.orange.opacity(0.15) : 
                Color(.systemBackground).opacity(0.7),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isSelected ? Color.orange.opacity(0.7) : Color.primary.opacity(0.15), 
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
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
