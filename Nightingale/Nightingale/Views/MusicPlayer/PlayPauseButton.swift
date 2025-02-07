import SwiftUI

struct PlayPauseButton: View {
    @ObservedObject var musicQueue = MusicQueue.shared
    @ObservedObject var playerManager = PlayerManager.shared // Observe playback state

    var body: some View {
        Button(action: {
            if let song = musicQueue.nextSong {
                playerManager.togglePlayback(for: song) // Play/Pause the current song
            }
        }) {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill") // ✅ Outlined icons
                .resizable()
                .frame(width: 25, height: 25)
                .foregroundColor(.white) // ✅ White icon
                .padding(.horizontal, 10) // ✅ Wider horizontally
            
        }
    }
}
