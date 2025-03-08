import SwiftUI

struct MusicSelector: View {
    @ObservedObject private var playlistManager = PlaylistsManager.shared
    @State private var selectedPlaylist: String = "All" // Default to All Music
    

    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            PlaylistsSelector(selectedPlaylist: $selectedPlaylist)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    RemoveButton()
                    AddButton()
                }
                
                Playlist(selectedPlaylist: $selectedPlaylist)
            }
            .padding(0)
        }
    }
}


