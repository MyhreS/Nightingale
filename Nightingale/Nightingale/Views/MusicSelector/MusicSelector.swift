import SwiftUI

struct MusicSelector: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared
    @ObservedObject var playlistManager = PlaylistManager.shared
    @State private var selectedPlaylist: String = "All" // Default to All Music
    @State private var showAddNewPlaylist = false
    
    private var filteredSongs: [Song] {
        if selectedPlaylist == "All" {
            // Show all songs in a single list, sorted by playlist then name
            return musicLibrary.songs.sorted { (song1, song2) in
                let playlist1 = playlistManager.playlistForSong(song1.id) ?? ""
                let playlist2 = playlistManager.playlistForSong(song2.id) ?? ""
                return (playlist1, song1.fileName) < (playlist2, song2.fileName)
            }
        } else {
            // Show songs from selected playlist
            return playlistManager.songsInPlaylist(selectedPlaylist)
                .sorted { $0.fileName < $1.fileName }
        }
    }

    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Playlist")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Add new playlist button
                    Button(action: { showAddNewPlaylist = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                
                // Playlist selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // All option
                        TagButton(tag: "All", isSelected: selectedPlaylist == "All") {
                            selectedPlaylist = "All"
                            provideHapticFeedback()
                        }
                        
                        // User-created playlists
                        ForEach(playlistManager.getPlaylists(), id: \.self) { playlist in
                            TagButton(tag: playlist, isSelected: selectedPlaylist == playlist) {
                                selectedPlaylist = playlist
                                provideHapticFeedback()
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                }
                .padding(.vertical, 5)

                if filteredSongs.isEmpty {
                    VStack {
                        if musicLibrary.songs.isEmpty {
                            Text("No music added yet. Go to settings to add some!")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.leading, 0)
                        } else {
                            Text("No songs in this playlist")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .padding(.leading, 0)
                        }
                        
                        Rectangle()
                            .fill(Color.clear)
                            .frame(maxHeight: .infinity)
                            .padding(0)
                    }
                } else {
                    MusicList(songs: filteredSongs)
                }
            }
        }
        .padding(10)
        .sheet(isPresented: $showAddNewPlaylist) {
            AddNewPlaylistSheet(isPresented: $showAddNewPlaylist, selectedPlaylist: $selectedPlaylist)
        }
    }
}

// Updated AddNewPlaylistSheet
private struct AddNewPlaylistSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedPlaylist: String
    @ObservedObject private var playlistManager = PlaylistManager.shared
    
    @State private var newPlaylistName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter playlist name", text: $newPlaylistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        createPlaylist()
                    }
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !newPlaylistName.isEmpty && playlistManager.getPlaylists().contains(newPlaylistName) {
                    Text("This playlist already exists")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: createPlaylist) {
                    Text("Create Playlist")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newPlaylistName.isEmpty || playlistManager.getPlaylists().contains(newPlaylistName))
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("New Playlist")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func createPlaylist() {
        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        if playlistManager.createPlaylist(trimmedName) {
            selectedPlaylist = trimmedName
            isPresented = false
        }
    }
}
