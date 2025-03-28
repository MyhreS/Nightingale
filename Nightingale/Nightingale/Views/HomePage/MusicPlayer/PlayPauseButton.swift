import SwiftUI

struct PlayPauseButton: View {
    //@ObservedObject var musicQueue = MusicQueue.shared
    @ObservedObject var playerManager = PlayerManager.shared
    
    var body: some View {
        Button(action: {
            provideHapticFeedback()
            print("[PlayPauseButton] 👆 Button tapped, current isPlaying state: \(playerManager.isPlaying)")
            //if let song = musicQueue.currentSong {
                //playerManager.togglePlayback(for: song)
            //}
        }) {
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
        .animation(.easeInOut(duration: 0.1), value: playerManager.isPlaying)
        .onChange(of: playerManager.isPlaying) { newValue in
            print("[PlayPauseButton] 🔄 isPlaying changed to: \(newValue)")
        }
    }
}
