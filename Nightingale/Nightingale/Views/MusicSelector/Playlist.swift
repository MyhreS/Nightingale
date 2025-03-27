import SwiftUI

struct Playlist: View {
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @Binding var selectedPlaylist: String
    
    private var filteredSongs: [Song] {
        if selectedPlaylist == "All" {
            return musicLibrary.songs
        }
        return musicLibrary.songs.filter{$0.playlist == selectedPlaylist}
    }
    
    var body: some View {
        if filteredSongs.isEmpty {
            VStack {
                if musicLibrary.songs.isEmpty {
                    Text("No music added yet. Click on the plus (+) button to add some!")
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
            List($musicLibrary.songs, id: \.self) { $song in
                if selectedPlaylist == "All" || song.playlist == selectedPlaylist {
                    MusicItem(song: $song)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.leading, 0)
        }
    }
}
