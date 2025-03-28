import SwiftUI
import AVFoundation

struct EditMusic: View {
    @Binding var song: Song

    @State private var showPlaylistPicker = false
    @State private var showStartTimeEditor = false

    var body: some View {
        ZStack {
            Color.clear
                .contentShape(Rectangle())

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

                        Text(song.playlist.isEmpty ? "Not in playlist" : song.playlist)
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
                                Text(song.playlist.isEmpty ? "Add to Playlist" : "Current Playlist: \(song.playlist)")
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
            StartTimeEditor(song: $song)
        }
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPickerSheet(song: $song)
        }
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
