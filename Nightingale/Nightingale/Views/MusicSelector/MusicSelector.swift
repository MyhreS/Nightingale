import SwiftUI

struct MusicSelector: View {
    @ObservedObject private var playlistManager = PlaylistsManager.shared
    @State private var selectedPlaylist: String = "All" // Default to All Music
    

    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Playlist")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    AddButton()
                }
                //PlaylistSelector(selectedPlaylist: $selectedPlaylist)
                Playlist(selectedPlaylist: $selectedPlaylist)
            }
        }
        .padding(10)
    }
}


