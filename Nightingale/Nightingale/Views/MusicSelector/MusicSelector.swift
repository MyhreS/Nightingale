import SwiftUI

struct MusicSelector: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared // Access shared music library

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Playlist")
                .font(.headline)
                .fontWeight(.bold)

            if musicLibrary.musicFiles.isEmpty {
                Text("No music added yet. Go to settings to add some!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                MusicList()
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(20)

        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Border
        )
        
    }
}
