import SwiftUI

struct PlaylistsSelector: View {
    @ObservedObject var playlistManager = PlaylistsManager.shared
    @Binding var selectedPlaylist: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                TagButton(tag: "All", isSelected: selectedPlaylist == "All") {
                    selectedPlaylist = "All"
                    provideHapticFeedback()
                }
                
                ForEach(playlistManager.playlists, id: \.self) { playlist in
                    TagButton(tag: playlist, isSelected: selectedPlaylist == playlist) {
                        selectedPlaylist = playlist
                        provideHapticFeedback()
                    }
                }
            }
            .padding(.horizontal, 5)
        }
        .padding(.vertical, 5)
    }
}
