import SwiftUI
import AVFoundation

struct EditMusic: View {
    @Environment(\.dismiss) private var dismiss
    let song: MusicFile
    let onSave: (MusicFile) -> Void
    
    @State private var startTime: Double
    @State private var isPreviewPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?
    @State private var showPlaylistPicker = false
    @State private var showStartTimeEditor = false
    private let playerManager = PlayerManager.shared
    @ObservedObject private var playlistManager = PlaylistManager.shared
    
    init(song: MusicFile, onSave: @escaping (MusicFile) -> Void) {
        self.song = song
        self.onSave = onSave
        self._startTime = State(initialValue: song.startTime)
        self._currentPlayTime = State(initialValue: song.startTime)
    }
    
    private var currentPlaylist: String? {
        playlistManager.playlistForSong(song.id)
    }
    
    var body: some View {
        ZStack {
            // Background tap area to dismiss
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: 0) {
                // Song header
                HStack(spacing: 16) {
                    // Music icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: "music.note")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    // Song details
                    VStack(alignment: .leading, spacing: 4) {
                        Text(song.name)
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
                
                // Options List
                List {
                    Section {
                        // Add to playlist / Current playlist
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
                        
                        // Edit start time
                        Button(action: { showStartTimeEditor = true }) {
                            HStack {
                                Image(systemName: "clock")
                                    .frame(width: 25)
                                Text("Edit Start Time")
                                Spacer()
                                Text(formatTime(startTime))
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
        .sheet(isPresented: $showPlaylistPicker) {
            PlaylistPicker(song: song, isPresented: $showPlaylistPicker)
        }
        .sheet(isPresented: $showStartTimeEditor) {
            StartTimeEditor(song: song, startTime: $startTime, isPresented: $showStartTimeEditor)
                .onDisappear {
                    var updatedSong = song
                    updatedSong.startTime = startTime
                    onSave(updatedSong)
                }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Playlist Picker Sheet
private struct PlaylistPicker: View {
    let song: MusicFile
    @Binding var isPresented: Bool
    @ObservedObject private var playlistManager = PlaylistManager.shared
    
    private var currentPlaylist: String? {
        playlistManager.playlistForSong(song.id)
    }
    
    var body: some View {
        NavigationView {
            List {
                Button(action: {
                    if let current = currentPlaylist {
                        playlistManager.removeSongFromPlaylist(songId: song.id, playlist: current)
                    }
                    isPresented = false
                }) {
                    HStack {
                        Text("Remove from Playlist")
                            .foregroundColor(.red)
                        Spacer()
                        if currentPlaylist == nil {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                ForEach(playlistManager.getPlaylists(), id: \.self) { playlist in
                    Button(action: {
                        // Remove from current playlist if needed
                        if let current = currentPlaylist, current != playlist {
                            playlistManager.removeSongFromPlaylist(songId: song.id, playlist: current)
                        }
                        // Add to new playlist
                        playlistManager.addSongToPlaylist(songId: song.id, playlist: playlist)
                        isPresented = false
                    }) {
                        HStack {
                            Text(playlist)
                            Spacer()
                            if currentPlaylist == playlist {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Choose Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
    }
}

// Start Time Editor Sheet
private struct StartTimeEditor: View {
    let song: MusicFile
    @Binding var startTime: Double
    @Binding var isPresented: Bool
    @State private var isPreviewPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?
    private let playerManager = PlayerManager.shared
    
    init(song: MusicFile, startTime: Binding<Double>, isPresented: Binding<Bool>) {
        self.song = song
        self._startTime = startTime
        self._isPresented = isPresented
        self._currentPlayTime = State(initialValue: startTime.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Current time display
                Text(formatTime(startTime))
                    .font(.system(size: 48, weight: .medium, design: .rounded))
                    .monospacedDigit()
                
                // Time slider
                Slider(value: $startTime, in: 0...song.duration) { editing in
                    if !editing && isPreviewPlaying {
                        stopPreview()
                        startPreview()
                    }
                }
                .padding(.horizontal)
                
                // Duration
                Text("Duration: \(formatTime(song.duration))")
                    .foregroundColor(.gray)
                
                // Preview button
                Button(action: togglePreview) {
                    Image(systemName: isPreviewPlaying ? "stop.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 70, height: 70)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                
                if showProgress {
                    // Preview progress
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            
                            Capsule()
                                .fill(Color.blue)
                                .frame(width: max(0, min(geometry.size.width * (currentPlayTime / song.duration), geometry.size.width)), height: 4)
                        }
                    }
                    .frame(height: 4)
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Start Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { isPresented = false }
                }
            }
        }
        .onDisappear {
            stopPreview()
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func startPreview() {
        showProgress = true
        isPreviewPlaying = true
        currentPlayTime = startTime
        var previewSong = song
        previewSong.startTime = startTime
        playerManager.previewPlay(previewSong)
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if currentPlayTime < song.duration {
                currentPlayTime += 0.1
            } else {
                stopPreview()
            }
        }
    }
    
    private func stopPreview() {
        isPreviewPlaying = false
        timer?.invalidate()
        timer = nil
        playerManager.stopPreview()
        showProgress = false
    }
    
    private func togglePreview() {
        if isPreviewPlaying {
            stopPreview()
        } else {
            startPreview()
        }
    }
} 