import SwiftUI

struct MusicPlayer: View {
    var body: some View {
        HStack(spacing: 10) {
            CurrentQueued()
            PlayPauseButton()
        }
        .frame(maxWidth: .infinity, maxHeight: 70)
        .padding(10)
        .background(Color.blue.opacity(0.5))
        .cornerRadius(20)

        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Border
        )
    }
}
