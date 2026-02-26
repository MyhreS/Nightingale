import SwiftUI

struct SongRow: View {
    let song: Song
    let isSelected: Bool
    let isPlayed: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void

    private var resolvedArtist: String {
        let base = song.artistName.trimmingCharacters(in: .whitespaces)
        guard !base.isEmpty else { return "" }
        return base.hasPrefix("Remixed by:") ? base : "by \(base)"
    }

    var body: some View {
        HStack(spacing: 14) {
            CachedAsyncImage(url: URL(string: song.artworkURL)) { image in
                artworkView(for: image, songId: song.songId)
            }
            .frame(width: 52, height: 52)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack(alignment: .leading, spacing: 5) {
                Text(song.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                if !resolvedArtist.isEmpty {
                    Text(resolvedArtist)
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            
            Spacer(minLength: 12)
            
            if isPlayed && !isSelected {
                Text("Played")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
        .background(
            isSelected ? 
                Color(white: 0.15) : 
                Color(white: 0.08),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    isSelected ? Color.white.opacity(0.3) : Color(white: 0.2), 
                    lineWidth: isSelected ? 2 : 1
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onLongPressGesture {
            onLongPress()
        }
    }

    private static let iconPalette: [Color] = [
        Color(red: 0.35, green: 0.60, blue: 0.95),
        Color(red: 0.90, green: 0.45, blue: 0.50),
        Color(red: 0.40, green: 0.78, blue: 0.55),
        Color(red: 0.95, green: 0.70, blue: 0.30),
        Color(red: 0.65, green: 0.50, blue: 0.90),
        Color(red: 0.85, green: 0.55, blue: 0.80),
        Color(red: 0.45, green: 0.75, blue: 0.80),
        Color(red: 0.90, green: 0.60, blue: 0.40),
    ]

    private func artworkView(for image: Image?, songId: String) -> some View {
        Group {
            if let image {
                image
                    .resizable()
                    .scaledToFill()
            } else {
                let color = Self.iconPalette[abs(songId.hashValue) % Self.iconPalette.count]
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.2))
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 18))
                            .foregroundStyle(color)
                    )
            }
        }
    }
}
