import SwiftUI

struct Playlist: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared
   // @ObservedObject var playlistManager = PlaylistManager.shared
    @Binding var selectedPlaylist: String
    
    private var filteredSongs: [Song] {
        /*
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
        */
        return musicLibrary.songs
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
            List(filteredSongs, id: \.self) { file in
                MusicItem(musicFile: file)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.leading, 0)
        }
    }
}
