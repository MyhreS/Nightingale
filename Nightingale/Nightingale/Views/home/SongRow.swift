import SwiftUI

struct SongRow: View {
    let song: Song
    let isSelected: Bool
    let isPlayed: Bool
    let isDisabled: Bool
    let statusLabel: String?
    let overlayLabel: String?
    let isPlaying: Bool
    let isLoading: Bool
    let loadingProgress: Double
    let playbackLabel: String?
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onAppearInViewport: () -> Void
    let onDisappearFromViewport: () -> Void
    @State private var isPlayingPulse = false
    @State private var isLoadingPulse = false

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
            
            if isLoading {
                Text("Loading")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(red: 0.64, green: 0.88, blue: 0.72).opacity(0.95))
            } else if let playbackLabel, isPlaying {
                Text(playbackLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.82))
            } else if let statusLabel {
                Text(statusLabel)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(white: 0.55))
            } else if isPlayed && !isSelected {
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
        .opacity(isDisabled ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            guard !isDisabled else { return }
            onTap()
        }
        .onLongPressGesture {
            guard !isDisabled else { return }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onLongPress()
        }
        .overlay(alignment: .center) {
            Group {
                if isPlaying {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            Color(red: 0.35, green: 0.75, blue: 0.45).opacity(isPlayingPulse ? 0.55 : 0.25),
                            lineWidth: isPlayingPulse ? 2 : 1
                        )
                        .scaleEffect(isPlayingPulse ? 1.02 : 1.0)
                        .allowsHitTesting(false)
                        .padding(2)
                        .animation(
                            .easeInOut(duration: 0.85).repeatForever(autoreverses: true),
                            value: isPlayingPulse
                        )
                }

                if isLoading {
                    loadingBorder
                        .transition(.opacity)
                }

                if let overlayLabel {
                    VStack(spacing: 0) {
                        Spacer()
                        Text(overlayLabel)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.72), in: Capsule())
                            .padding(.bottom, 8)
                    }
                }
            }
        }
        .onAppear {
            updatePulseAnimation(enabled: isPlaying || isLoading)
            updateLoadingAnimation(enabled: isLoading)
            onAppearInViewport()
        }
        .onDisappear {
            onDisappearFromViewport()
        }
        .onChange(of: isPlaying) { _, nowPlaying in
            updatePulseAnimation(enabled: nowPlaying || isLoading)
        }
        .onChange(of: isLoading) { _, nowLoading in
            updatePulseAnimation(enabled: isPlaying || nowLoading)
            updateLoadingAnimation(enabled: nowLoading)
        }
    }

    private var loadingBorder: some View {
        GeometryReader { proxy in
            let lineWidth: CGFloat = 3
            let horizontalInset: CGFloat = 12
            let availableWidth = max(0, proxy.size.width - (horizontalInset * 2))
            let progressWidth = availableWidth * max(0, min(loadingProgress, 1))

            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        Color(red: 0.42, green: 0.82, blue: 0.56).opacity(0.12 + (isLoadingPulse ? 0.05 : 0)),
                        lineWidth: 1
                    )
                    .padding(2)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.34, green: 0.78, blue: 0.50),
                                Color(red: 0.66, green: 0.90, blue: 0.72),
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth, height: lineWidth)
                    .shadow(color: Color(red: 0.38, green: 0.86, blue: 0.58).opacity(0.35), radius: 6, x: 0, y: 0)
                    .padding(.leading, horizontalInset)
                    .padding(.bottom, 4)
                    .opacity(isLoadingPulse ? 1.0 : 0.8)
                    .animation(.easeOut(duration: 0.2), value: loadingProgress)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isLoadingPulse)
            }
        }
        .allowsHitTesting(false)
        .padding(1)
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

    private func updatePulseAnimation(enabled: Bool) {
        if enabled {
            isPlayingPulse = false
            withAnimation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                isPlayingPulse = true
            }
        } else {
            isPlayingPulse = false
        }
    }

    private func updateLoadingAnimation(enabled: Bool) {
        if enabled {
            isLoadingPulse = false
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                isLoadingPulse = true
            }
        } else {
            isLoadingPulse = false
        }
    }
}
