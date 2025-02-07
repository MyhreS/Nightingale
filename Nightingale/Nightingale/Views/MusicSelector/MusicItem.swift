import SwiftUI

struct MusicItem: View {
    @ObservedObject var musicQueue = MusicQueue.shared // Use the shared MusicQueue instance
    @State private var isAddedToQueue = false // Tracks whether the item was recently added

    var file: URL

    var body: some View {
        Button(action: {
            addToQueue(file) // Add the item to the queue
            provideHapticFeedback() // Provide tactile feedback
        }) {
            HStack {
                Text(file.lastPathComponent)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear) // Highlight when added
                    )
            }
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
        .listRowBackground(Color.clear) // Ensure the row background is transparent
        .background(Color.clear) // Additional background transparency for the button
        .overlay(
            // Show a green checkmark when added
            Group {
                if isAddedToQueue {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.opacity)
                        .animation(.easeInOut, value: isAddedToQueue) // Smooth animation
                        .offset(x: 100) // Adjust checkmark position
                }
            }
        )
    }

    /// Adds the file to the queue and shows feedback
    private func addToQueue(_ file: URL) {
        musicQueue.addToQueue(file) // Add the file to the shared MusicQueue
        showAddedFeedback() // Show visual feedback
    }

    /// Displays visual feedback for 2 seconds
    private func showAddedFeedback() {
        isAddedToQueue = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isAddedToQueue = false
        }
    }

    /// Provides haptic feedback when the button is tapped
    private func provideHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}
