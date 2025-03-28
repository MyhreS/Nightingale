import SwiftUI

struct CreatePlaylistSheet: View {
    @Binding var isPresented: Bool
    @Binding var successfullyAddedPlaylist: Bool
    
    @State private var playlistName: String = ""
    @State private var selectedSongIDs: Set<String> = []
    @ObservedObject private var musicLibrary = MusicLibrary.shared

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter playlist name", text: $playlistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .frame(maxWidth: .infinity)

                List(musicLibrary.songs) { song in
                    Button(action: {
                        if selectedSongIDs.contains(song.id) {
                            selectedSongIDs.remove(song.id)
                        } else {
                            selectedSongIDs.insert(song.id)
                        }
                    }) {
                        HStack {
                            Text(song.fileName)
                            Spacer()
                            if selectedSongIDs.contains(song.id) {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }

                Button(action: {
                    guard !playlistName.isEmpty, !selectedSongIDs.isEmpty else { return }

                    // Update playlist property for selected songs
                    for index in musicLibrary.songs.indices {
                        if selectedSongIDs.contains(musicLibrary.songs[index].id) {
                            var updated = musicLibrary.songs[index]
                            updated.playlist = playlistName
                            musicLibrary.editMusicFile(updated)
                        }
                    }

                    successfullyAddedPlaylist = true
                    isPresented = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        successfullyAddedPlaylist = false
                    }
                }) {
                    Text("Create Playlist")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background((playlistName.isEmpty || selectedSongIDs.isEmpty) ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                .disabled(playlistName.isEmpty || selectedSongIDs.isEmpty)

                Spacer()
            }
            .navigationTitle("New Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
