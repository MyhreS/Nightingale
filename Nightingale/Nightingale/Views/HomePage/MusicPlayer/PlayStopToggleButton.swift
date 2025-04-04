import SwiftUI

struct PlayStopToggleButton: View {
    @ObservedObject private var audioPlayer = AudioPlayer()
    @ObservedObject private var audioQueue = AudioQueue.shared
    

    var body: some View {
        Button(action: {
            togglePlay()
            provideHapticFeedback()
        }) {
            Image(systemName: audioPlayer.isPlaying ? "stop.fill" : "play.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.1), value: audioPlayer.isPlaying)
        .disabled(audioQueue.song == nil)
        .onChange(of: audioQueue.song) { oldValue, newValue in
            if (audioQueue.playOnSelect) {
                guard let song = newValue else { return }
                audioPlayer.play(song)
            }
        }
    }
    
    private func togglePlay() {
        if audioPlayer.isPlaying {
            audioPlayer.stop()
        } else {
            if audioQueue.song != nil {
                guard let song = audioQueue.song else { return }
                audioPlayer.play(song)
            }
            
        }
    }
}
