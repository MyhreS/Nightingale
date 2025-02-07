import SwiftUI

struct MusicItem: View {
    @ObservedObject var musicQueue = MusicQueue.shared // Shared music queue

    var file: URL

    var body: some View {
        Button(action: {
            addToQueue(file) // Add to queue
            provideHapticFeedback() // Haptic feedback when tapped
        }) {
            HStack(spacing: 10) {
                // Music icon (squircle)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isNextToPlay() ? Color.green.opacity(0.8) : Color.blue.opacity(0.2)) // Highlight next song
                        .frame(width: 40, height: 40)

                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(isNextToPlay() ? .white : .blue)
                }

                // Song name
                Text(file.lastPathComponent)
                    .font(.body)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(5)
            .frame(maxWidth: .infinity) // Expand button to fill available space
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isNextToPlay() ? Color.green.opacity(0.2) : Color.clear) // Subtle highlight for next song
            )
            .contentShape(Rectangle()) // Make the entire area tappable
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
        .listRowInsets(EdgeInsets()) // Remove default insets
        .listRowBackground(Color.clear) // Transparent row background
    }

    /// ✅ Checks if this item is the next one to be played
    private func isNextToPlay() -> Bool {
        return musicQueue.nextSong == file
    }

    /// Adds the file to the queue and updates UI
    private func addToQueue(_ file: URL) {
        musicQueue.addToQueue(file)
    }

    /// ✅ Provides haptic feedback when the button is tapped
    private func provideHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
