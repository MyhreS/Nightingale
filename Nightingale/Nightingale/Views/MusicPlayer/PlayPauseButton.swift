import SwiftUI

struct PlayPauseButton: View {
    @ObservedObject var musicQueue = MusicQueue.shared
    @ObservedObject var playerManager = PlayerManager.shared
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundColor(.blue)
                .overlay(
                    Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(.black.opacity(0.15))
                        .offset(x: 0.5, y: 0.5)
                )
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 2, y: 2)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    provideHapticFeedback()
                    if playerManager.isPlaying {
                        playerManager.pause()
                    }
                    playerManager.queueNextUnplayedSong()
                }
        )
        .highPriorityGesture(
            TapGesture()
                .onEnded {
                    provideHapticFeedback()
                    if let song = musicQueue.nextSong {
                        playerManager.togglePlayback(for: song)
                    }
                }
        )
        .animation(.easeInOut(duration: 0.1), value: playerManager.isPlaying)
    }
}
