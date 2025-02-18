import SwiftUI

struct MusicPlayer: View {
    var body: some View {
        HStack(spacing: 10) {
            CurrentQueued()
            PlayPauseButton()
        }
        .frame(maxWidth: .infinity, maxHeight: 70)
        .padding(10)
        .background(Color(uiColor: .systemBackground)) // White card background
        .cornerRadius(20)
        // Update shadow to be more subtle
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
