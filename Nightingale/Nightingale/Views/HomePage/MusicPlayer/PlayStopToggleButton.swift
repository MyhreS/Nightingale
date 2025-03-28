import SwiftUI

struct PlayStopToggleButton: View {
    @State private var isPlaying = false

    var body: some View {
        Button(action: {
            provideHapticFeedback()
            isPlaying.toggle()
            print("[PlayStopToggleButton] 👆 Toggled isPlaying to \(isPlaying)")
        }) {
            Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundColor(.white)
        }
        .animation(.easeInOut(duration: 0.1), value: isPlaying)
    }
}
