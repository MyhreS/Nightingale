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
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
                .padding(10)
                .background(Color.blue)
                .clipShape(Circle())
        }
    }
}
