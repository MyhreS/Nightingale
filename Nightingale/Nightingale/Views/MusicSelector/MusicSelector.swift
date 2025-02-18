import SwiftUI

struct MusicSelector: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared
    @State private var selectedTag: String = "All" // Default to All Music
    @State private var showAddNewTag = false
    
    private var untaggedSongs: [MusicFile] {
        musicLibrary.musicFiles.filter { $0.tag.isEmpty }
    }
    
    private var availableTags: [String] {
        var tags = Set(musicLibrary.musicFiles.map { $0.tag })
        tags.remove("") // Remove empty tag since it's handled separately
        return Array(tags).sorted()
    }
    
    private var filteredSongs: [MusicFile] {
        if selectedTag == "All" {
            // Show all songs, sorted by tag (untagged first)
            let untagged = untaggedSongs
            let tagged = musicLibrary.musicFiles.filter { !$0.tag.isEmpty }
                .sorted { ($0.tag, $0.name) < ($1.tag, $1.name) }
            return untagged + tagged
        } else if selectedTag.isEmpty {
            // Show untagged songs
            return untaggedSongs
        } else {
            // Show songs from selected playlist
            return musicLibrary.musicFiles.filter { $0.tag == selectedTag }
                .sorted { $0.name < $1.name }
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
                    Button(action: { showAddNewTag = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title3)
                    }
                }
                
                // Tag selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        // All Music option
                        TagButton(tag: "All Music", isSelected: selectedTag == "All") {
                            selectedTag = "All"
                            provideHapticFeedback()
                        }
                        
                        // No Playlist option - only show if there are untagged songs
                        if !untaggedSongs.isEmpty {
                            TagButton(tag: "No Playlist", isSelected: selectedTag.isEmpty) {
                                selectedTag = ""
                                provideHapticFeedback()
                            }
                        }
                        
                        // User-created playlists
                        ForEach(availableTags, id: \.self) { tag in
                            TagButton(tag: tag, isSelected: selectedTag == tag) {
                                selectedTag = tag
                                provideHapticFeedback()
                            }
                        }
                    }
                    .padding(.horizontal, 5)
                }
                .padding(.vertical, 5)

                if filteredSongs.isEmpty {
                    VStack {
                        if musicLibrary.musicFiles.isEmpty {
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
                    if selectedTag == "All" {
                        // Group songs by playlist in All view
                        VStack(alignment: .leading, spacing: 15) {
                            if !untaggedSongs.isEmpty {
                                PlaylistSection(title: "No Playlist", songs: untaggedSongs)
                            }
                            
                            ForEach(availableTags, id: \.self) { tag in
                                let songs = musicLibrary.musicFiles.filter { $0.tag == tag }
                                if !songs.isEmpty {
                                    PlaylistSection(title: tag, songs: songs.sorted { $0.name < $1.name })
                                }
                            }
                        }
                    } else {
                        MusicList(songs: filteredSongs)
                    }
                }
            }
        }
        .padding(10)
        .sheet(isPresented: $showAddNewTag) {
            AddNewPlaylistSheet(isPresented: $showAddNewTag, selectedTag: $selectedTag)
        }
    }
}

// Playlist section component for All view
private struct PlaylistSection: View {
    let title: String
    let songs: [MusicFile]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            MusicList(songs: songs)
        }
    }
}

// Updated AddNewPlaylistSheet
private struct AddNewPlaylistSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedTag: String
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    
    @State private var newPlaylistName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    private var existingPlaylists: Set<String> {
        Set(musicLibrary.musicFiles.map { $0.tag }).subtracting(["", "All"])
    }
    
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
                
                if !newPlaylistName.isEmpty && existingPlaylists.contains(newPlaylistName) {
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
                .disabled(newPlaylistName.isEmpty || existingPlaylists.contains(newPlaylistName))
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
        if !trimmedName.isEmpty && !existingPlaylists.contains(trimmedName) {
            // Create a new empty playlist by updating the selected tag
            selectedTag = trimmedName
            
            // If there are untagged songs, move one to the new playlist
            if let firstUntaggedSong = musicLibrary.musicFiles.first(where: { $0.tag.isEmpty }) {
                var updatedSong = firstUntaggedSong
                updatedSong.tag = trimmedName
                musicLibrary.updateSong(updatedSong)
            }
            
            isPresented = false
        }
    }
}
