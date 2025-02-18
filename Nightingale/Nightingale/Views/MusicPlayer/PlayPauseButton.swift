import SwiftUI

struct PlayPauseButton: View {
    @ObservedObject var musicQueue = MusicQueue.shared
    @ObservedObject var playerManager = PlayerManager.shared // Observe playback state

    var body: some View {
        Button(action: {
            provideHapticFeedback()
            if let song = musicQueue.nextSong {
                playerManager.togglePlayback(for: song) // Play/Pause the current song
            }
        }) {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill") // ✅ Filled icons
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue) // Changed to blue
                .overlay(
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.black.opacity(0.15)) // ✅ Slight black stroke effect
                        .offset(x: 0.5, y: 0.5) // ✅ Mimic a subtle stroke
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 2, y: 2) // ✅ Soft shadow
                .padding(.trailing, 10)
        }
    }
}
