import SwiftUI

struct PlaylistPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var song: Song
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @State private var selectedPlaylist: String?
    
    private var playlists: [String] {
        let nonEmptyPlaylists = musicLibrary.songs.map { $0.playlist }.filter { !$0.isEmpty }
        let uniquePlaylists = Set(nonEmptyPlaylists)
        return uniquePlaylists.sorted()
    }
    
    private func addSongToPlaylist(playlist: String) {
        song.playlist = playlist
        musicLibrary.editMusicFile(song)
        dismiss()
    }
    
    var body: some View {
        NavigationView {
            List(playlists, id: \.self) { playlist in
                Button(action: {
                    addSongToPlaylist(playlist: playlist)
                }) {
                    Text(playlist)
                }
            }
            .navigationTitle("Select Playlist")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() }
            )
        }
    }
}
