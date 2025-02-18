import SwiftUI

struct MusicSelector: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared // Access shared music library

    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Playlist")
                    .font(.headline)
                    .fontWeight(.bold)

                if musicLibrary.musicFiles.isEmpty {
                    VStack {
                        Text("No music added yet. Go to settings to add some!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading, 0)
                        
                        // Invisible placeholder that takes up space
                        Rectangle()
                            .fill(Color.clear)
                            .frame(maxHeight: .infinity)
                            .padding(0)// Adjust height based on desired space
                    }
                } else {
                    MusicList()
                }
            }
        }
        .padding(10)
    }
        
}
