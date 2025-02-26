import SwiftUI

struct MusicItem: View {
    @ObservedObject var musicQueue = MusicQueue.shared // Shared music queue
    @ObservedObject var musicLibrary = MusicLibrary.shared
    var musicFile: MusicFile
    @State private var showEditSheet = false
    
    init(musicFile: MusicFile) {
        self.musicFile = musicFile
    }
    
    var body: some View {
        Button(action: {
            addToQueue(musicFile) // Add to queue
            provideHapticFeedback() // Haptic feedback when tapped
        }) {
            HStack(spacing: 10) {
                // Music icon (squircle)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBackgroundColor()) // Adjust background color based on conditions
                        .frame(width: 40, height: 40)

                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(iconForegroundColor()) // Adjust icon color based on conditions
                }

                // Song name
                Text(musicFile.name)
                    .font(.body)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Edit button
                Button(action: {
                    showEditSheet = true
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(10)
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
        .sheet(isPresented: $showEditSheet) {
            EditMusic(song: musicFile) { updatedSong in
                musicLibrary.updateSong(updatedSong)
            }
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
    }

    /// Checks if this item is the next one to be played
    private func isNextToPlay() -> Bool {
        return musicQueue.currentSong?.id == musicFile.id
    }

    /// Determines the background color of the icon
    private func iconBackgroundColor() -> Color {
        if isNextToPlay() {
            return Color.green.opacity(0.8)
        } else if musicFile.played {
            return Color.gray.opacity(0.3) // Gray for played songs
        } else {
            return Color.blue.opacity(0.2)
        }
    }

    /// Determines the foreground color of the icon
    private func iconForegroundColor() -> Color {
        if isNextToPlay() {
            return .white
        } else if musicFile.played {
            return .gray // Lighter gray for played songs
        } else {
            return .blue
        }
    }

    /// Adds the file to the queue and updates UI
    private func addToQueue(_ musicFile: MusicFile) {
        print("[MusicItem] 🎵 Adding song to queue: \(musicFile.name), startTime: \(musicFile.startTime)")
        // Stop any current playback
        PlayerManager.shared.stop()
        // Add to queue (this will also update upcoming song)
        musicQueue.addToQueue(musicFile)
    }
}
