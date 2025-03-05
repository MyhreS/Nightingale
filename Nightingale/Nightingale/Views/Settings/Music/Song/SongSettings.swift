import SwiftUI
import AVFoundation

struct SongSettings: View {
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @State private var editingSong: MusicFile?
    @State private var isPlaying = false
    private let playerManager = PlayerManager.shared
    
    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Song Settings")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    if editingSong != nil {
                        Button(action: { editingSong = nil }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                if musicLibrary.getMusicFiles().isEmpty {
                    Text("No songs added yet")
                        .foregroundColor(.gray)
                        .padding(.vertical)
                } else {
                    if let song = editingSong {
                        SongEditor(song: song) { updatedSong in
                            musicLibrary.editMusicFile(updatedSong)
                            editingSong = nil
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(musicLibrary.getMusicFiles()) { song in
                                    SongRow(song: song, isSelected: false) {
                                        editingSong = song
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}


