import SwiftUI
import AVFoundation

struct EditMusic: View {
    @Environment(\.dismiss) private var dismiss
    let song: Song
    let onSave: (Song) -> Void

    @State private var isPreviewPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?
    @State private var showPlaylistPicker = false
    @State private var showStartTimeEditor = false
    private let playerManager = PlayerManager.shared

    init(song: Song, onSave: @escaping (Song) -> Void) {
        self.song = song
        self.onSave = onSave
        self._currentPlayTime = State(initialValue: song.startTime)
    }

    private var currentPlaylist: String? {
        return "Something"
    }

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }

            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.fileName)
                            .font(.headline)
                            .lineLimit(1)

                        Text(currentPlaylist ?? "Not in playlist")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }

                    Spacer()
                }
                .padding()

                Divider()

                List {
                    Section {
                        Button(action: { showPlaylistPicker = true }) {
                            HStack {
                                Image(systemName: "music.note.list")
                                    .frame(width: 25)
                                Text(currentPlaylist == nil ? "Add to Playlist" : "Current Playlist: \(currentPlaylist!)")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())

                        Button(action: { showStartTimeEditor = true }) {
                            HStack {
                                Image(systemName: "clock")
                                    .frame(width: 25)
                                Text("Edit Start Time")
                                Spacer()
                                Text(formatTime(song.startTime))
                                    .foregroundColor(.gray)
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
                .listStyle(.insetGrouped)
            }
            .background(Color(uiColor: .systemGroupedBackground))
        }
        .sheet(isPresented: $showStartTimeEditor) {
            StartTimeEditor(song: song) { updatedSong in
                print("[EditMusic] 🔄 Received updated song with startTime: \(updatedSong.startTime)")
                MusicLibrary.shared.editMusicFile(updatedSong)
                onSave(updatedSong)
            }
        }
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerSheet(song: song, currentPlaylist: currentPlaylist)
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
