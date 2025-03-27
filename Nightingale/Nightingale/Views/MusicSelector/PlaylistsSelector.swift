import SwiftUI

struct PlaylistsSelector: View {
    @Binding var selectedPlaylist: String
    @ObservedObject private var musicLibrary = MusicLibrary.shared

    private var playlists: [String] {
        let nonEmptyPlaylists = musicLibrary.songs.map { $0.playlist }.filter { !$0.isEmpty }
        let uniquePlaylists = Set(nonEmptyPlaylists)
        return ["All"] + uniquePlaylists.sorted()
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(playlists, id: \.self) { playlist in
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
