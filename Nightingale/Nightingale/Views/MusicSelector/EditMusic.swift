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
    private let playerManager = PlayerManager.shared
    
    init(song: MusicFile, onSave: @escaping (MusicFile) -> Void) {
        self.song = song
        self.onSave = onSave
        self._startTime = State(initialValue: song.startTime)
        self._currentPlayTime = State(initialValue: song.startTime)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Top navigation with Save/Cancel
            HStack {
                Button(action: { dismiss() }) {
                    Text("Cancel")
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                Button(action: {
                    var updatedSong = song
                    updatedSong.startTime = startTime
                    onSave(updatedSong)
                    dismiss()
                }) {
                    Text("Save")
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, 16)
            
            // Header with song name centered
            Text(song.name)
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
        }
        .padding(.horizontal, 16)
        .background(Color(uiColor: .systemBackground))
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
    }
    
    private func togglePreview() {
        if isPreviewPlaying {
            stopPreview()
        } else {
            currentPlayTime = startTime
            startPreview()
        }
    }
} 