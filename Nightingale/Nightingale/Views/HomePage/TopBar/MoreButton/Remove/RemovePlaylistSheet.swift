import SwiftUI

struct RemovePlaylistSheet: View {
    @Binding var successfullyRemoved: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedPlaylists: Set<String> = []
    
    @ObservedObject var musicLibrary = MusicLibrary.shared
    
    private var playlists: [String] {
        let nonEmptyPlaylists = musicLibrary.songs.map { $0.playlist }.filter { !$0.isEmpty }
        let uniquePlaylists = Set(nonEmptyPlaylists)
        return uniquePlaylists.sorted()
    }
    
    var body: some View {
        NavigationView {
            List(playlists, id: \.self) { playlist in
                HStack {
                    Text(playlist)
                    Spacer()
                    if selectedPlaylists.contains(playlist) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    togglePlaylistSelection(playlist)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Remove Playlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Remove") {
                        removeSelectedPlaylists()
                    }
                    .disabled(selectedPlaylists.isEmpty)
                }
            }
        }
    }

    private func togglePlaylistSelection(_ playlist: String) {
        if selectedPlaylists.contains(playlist) {
            selectedPlaylists.remove(playlist)
        } else {
            selectedPlaylists.insert(playlist)
        }
    }

    private func removeSelectedPlaylists() {
        for playlist in selectedPlaylists {
            let songsInPlaylist = musicLibrary.songs.filter { $0.playlist == playlist }
            for song in songsInPlaylist {
                var updatedSong = song
                updatedSong.playlist = ""
                musicLibrary.editMusicFile(updatedSong)
            }
        }
        successfullyRemoved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            successfullyRemoved = false
        }
        presentationMode.wrappedValue.dismiss()
    }
}
