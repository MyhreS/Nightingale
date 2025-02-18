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
                Text("Song Settings")
                    .font(.headline)
                    .fontWeight(.bold)
                
                if musicLibrary.musicFiles.isEmpty {
                    Text("No songs added yet")
                        .foregroundColor(.gray)
                        .padding(.vertical)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(musicLibrary.musicFiles) { song in
                                SongSettingsRow(song: song, isEditing: editingSong?.id == song.id) { updatedSong in
                                    musicLibrary.updateSong(updatedSong)
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
    }
}

struct SongSettingsRow: View {
    let song: MusicFile
    let isEditing: Bool
    let onUpdate: (MusicFile) -> Void
    
    @State private var startTime: String
    @State private var isPlaying = false
    private let playerManager = PlayerManager.shared
    
    init(song: MusicFile, isEditing: Bool, onUpdate: @escaping (MusicFile) -> Void) {
        self.song = song
        self.isEditing = isEditing
        self.onUpdate = onUpdate
        self._startTime = State(initialValue: String(format: "%.1f", song.startTime))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(song.name)
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack {
                // Start Time Input
                HStack {
                    Text("Start:")
                        .font(.caption)
                    TextField("0.0", text: $startTime)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                    Text("sec")
                        .font(.caption)
                }
                
                Spacer()
                
                // Preview Button
                Button(action: {
                    if isPlaying {
                        playerManager.stop()
                        isPlaying = false
                    } else {
                        // Create a temporary MusicFile with current start time
                        var previewSong = song
                        previewSong.startTime = Double(startTime) ?? 0.0
                        playerManager.play(previewSong)
                        isPlaying = true
                    }
                }) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                        .foregroundColor(.blue)
                }
                
                // Save Button
                Button(action: {
                    var updatedSong = song
                    updatedSong.startTime = Double(startTime) ?? 0.0
                    onUpdate(updatedSong)
                }) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
} 