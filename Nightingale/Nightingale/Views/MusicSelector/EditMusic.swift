import SwiftUI
import AVFoundation

struct EditMusic: View {
    @Environment(\.dismiss) private var dismiss
    let song: Song
    let onSave: (Song) -> Void
    
    @State private var startTime: Double
    @State private var isPreviewPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?
    @State private var showPlaylistPicker = false
    @State private var showStartTimeEditor = false
    private let playerManager = PlayerManager.shared
    @ObservedObject private var playlistManager = PlaylistsManager.shared
    
    init(song: Song, onSave: @escaping (Song) -> Void) {
        self.song = song
        self.onSave = onSave
        self._startTime = State(initialValue: song.startTime)
        self._currentPlayTime = State(initialValue: song.startTime)
    }
    
    private var currentPlaylist: String? {
        //playlistManager.playlistForSong(song.id)
        return "Something"
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
        .sheet(isPresented: $showStartTimeEditor) {
            StartTimeEditor(song: song, startTime: $startTime, isPresented: $showStartTimeEditor)
                .onDisappear {
                    print("[EditMusic] 🕒 onDisappear called, updating song with new startTime: \(startTime)")
                    var updatedSong = song
                    updatedSong.startTime = startTime
                    print("[EditMusic] 🔄 Calling onSave with updated song, startTime: \(updatedSong.startTime)")
                    
                    // Update the song in the library directly to ensure it's saved
                    MusicLibrary.shared.editMusicFile(updatedSong)
                    
                    // Also call the onSave callback
                    onSave(updatedSong)
                    
                    // Don't automatically play the song after editing
                }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}


private struct StartTimeEditor: View {
    let song: Song
    @Binding var startTime: Double
    @Binding var isPresented: Bool
    @State private var isPreviewPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?
    private let playerManager = PlayerManager.shared
    
    init(song: Song, startTime: Binding<Double>, isPresented: Binding<Bool>) {
        self.song = song
        self._startTime = startTime
        self._isPresented = isPresented
        self._currentPlayTime = State(initialValue: startTime.wrappedValue)
        print("[StartTimeEditor] 🔄 Initialized with song: \(song.fileName), startTime: \(startTime.wrappedValue)")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with song name centered
                Text(song.fileName)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                
                // Time information
                HStack {
                    // Start time
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Start:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(formatTime(startTime))
                            .monospacedDigit()
                            .font(.system(.body, design: .rounded))
                    }
                    .frame(width: 80, alignment: .leading)
                    
                    Spacer()
                    
                    // Played time (centered)
                    if showProgress {
                        VStack(alignment: .center, spacing: 6) {
                            Text("Played:")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(formatTime(currentPlayTime))
                                .monospacedDigit()
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    // Duration time
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Duration:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(formatTime(song.duration))
                            .monospacedDigit()
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.gray)
                    }
                    .frame(width: 80, alignment: .trailing)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 24)
                
                // Custom Slider with progress
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)
                        
                        // Playback progress
                        if showProgress {
                            Capsule()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: max(0, min(geometry.size.width * (currentPlayTime / song.duration), geometry.size.width)), height: 6)
                        }
                        
                        // Slider
                        Slider(value: $startTime, in: 0...song.duration)
                            .accentColor(.blue)
                            .onChange(of: startTime) { newValue in
                                print("[StartTimeEditor] 🕒 Start time changed to: \(newValue)")
                                if isPreviewPlaying {
                                    stopPreview()
                                }
                            }
                    }
                }
                .frame(height: 30)
                .padding(.horizontal, 24)
                
                // Preview button centered
                Button(action: togglePreview) {
                    Image(systemName: isPreviewPlaying ? "stop.fill" : "play.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .frame(width: 70, height: 70)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .navigationTitle("Edit Start Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { 
                        print("[StartTimeEditor] ✅ Done button pressed, final startTime: \(startTime)")
                        isPresented = false 
                    }
                }
            }
        }
        .onDisappear {
            print("[StartTimeEditor] 🔄 onDisappear called, final startTime: \(startTime)")
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
        print("[StartTimeEditor] ▶️ Starting preview with startTime: \(previewSong.startTime)")
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
        print("[StartTimeEditor] ⏹️ Stopping preview")
        playerManager.stopPreview()
        showProgress = false
    }
    
    private func togglePreview() {
        if isPreviewPlaying {
            stopPreview()
        } else {
            // Reset progress display when starting new playback
            currentPlayTime = startTime
            startPreview()
        }
    }
} 
