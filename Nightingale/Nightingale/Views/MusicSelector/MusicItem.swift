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
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isAddedToQueue ? Color.green.opacity(0.8) : Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40) // Squircle size
                        .animation(.easeInOut(duration: 0.3), value: isAddedToQueue)
                        .padding(.leading, 0)
                    
                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20) // Icon size
                        .foregroundColor(isAddedToQueue ? .white : .blue)
                        .animation(.easeInOut(duration: 0.3), value: isAddedToQueue)
                        .padding(.leading, 0)
                }
                .padding(.leading, 0)
                Text(file.lastPathComponent)
                    .font(.body)
                    .padding(0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.clear) // Highlight when added
                    )
            }
            .padding(.leading, 0)
        }
        .listRowBackground(Color.clear) // Ensure the row background is transparent
        .background(Color.clear) // Additional background transparency for the button
        .padding(0)
    }

    /// Adds the file to the queue and shows feedback
    private func addToQueue(_ file: URL) {
        print("Added")
        musicQueue.addToQueue(file) // Add the file to the shared MusicQueue
        showAddedFeedback() // Show visual feedback
    }

    /// Displays visual feedback for 2 seconds
    private func showAddedFeedback() {
        isAddedToQueue = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isAddedToQueue = false
        }
    }

    /// Provides haptic feedback when the button is tapped
    private func provideHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

/*
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
            HStack(spacing: 10) {
                // Music icon that flashes green
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isAddedToQueue ? Color.green.opacity(0.8) : Color.blue.opacity(0.2))
                        .frame(width: 40, height: 40) // Squircle size
                        .animation(.easeInOut(duration: 0.3), value: isAddedToQueue)

                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20) // Icon size
                        .foregroundColor(isAddedToQueue ? .white : .blue)
                        .animation(.easeInOut(duration: 0.3), value: isAddedToQueue)
                }

                // Song name in the middle
                Text(file.lastPathComponent)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(nil) // Allow wrapping if text is too long
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 10) // Vertical padding for the row
            .padding(.horizontal, 10) // Horizontal padding for content
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isAddedToQueue ? Color.green.opacity(0.2) : Color.clear) // Highlight background when added
            )
        }
        .buttonStyle(PlainButtonStyle()) // Remove default button styling
        .listRowInsets(EdgeInsets()) // Remove default list insets
        .listRowBackground(Color.clear) // Ensure the row background is transparent
    }

    /// Adds the file to the queue and shows feedback
    private func addToQueue(_ file: URL) {
        print("Adding")
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
*/
