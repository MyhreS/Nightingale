import SwiftUI

struct PlaylistSelector: View {
    @ObservedObject var playlistManager = PlaylistsManager.shared
    @Binding var selectedPlaylist: String
    
    var body: some View {
        // Playlist selector
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // All option
                TagButton(tag: "All", isSelected: selectedPlaylist == "All") {
                    selectedPlaylist = "All"
                    provideHapticFeedback()
                }
                
                /*
                // User-created playlists
                ForEach(playlistManager.getPlaylists(), id: \.self) { playlist in
                    TagButton(tag: playlist, isSelected: selectedPlaylist == playlist) {
                        selectedPlaylist = playlist
                        provideHapticFeedback()
                    }
                }
                 */
            }
            .padding(.horizontal, 5)
        }
        .padding(.vertical, 5)
    }
}
