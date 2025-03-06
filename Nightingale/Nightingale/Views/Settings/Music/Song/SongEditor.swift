import SwiftUI

struct SongEditor: View {
    let song: Song
    let onSave: (Song) -> Void
    
    @State private var startTime: Double
    @State private var isPreviewPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?
    private let playerManager = PlayerManager.shared
    
    init(song: Song, onSave: @escaping (Song) -> Void) {
        self.song = song
        self.onSave = onSave
        self._startTime = State(initialValue: song.startTime)
        self._currentPlayTime = State(initialValue: song.startTime)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(song.fileName)
                .font(.headline)
            
            // Time information
            VStack(alignment: .leading, spacing: 4) {
                // Start time and duration
                HStack {
                    VStack(alignment: .leading) {
                        Text("Start:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(formatTime(startTime))
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    if showProgress {
                        VStack(alignment: .center) {
                            Text("Played:")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            Text(formatTime(currentPlayTime))
                                .monospacedDigit()
                                .foregroundColor(.green)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("Duration:")
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text(formatTime(song.duration))
                            .monospacedDigit()
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 4)
            
            // Custom Slider with progress
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    // Playback progress
                    if showProgress {
                        Rectangle()
                            .fill(Color.green.opacity(0.7))
                            .frame(width: max(0, min(geometry.size.width * (currentPlayTime / song.duration), geometry.size.width)), height: 4)
                            .cornerRadius(2)
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
            
            // Preview controls
            HStack {
                Spacer()
                
                Button(action: togglePreview) {
                    Image(systemName: isPreviewPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.vertical, 5)
            
            // Save button
            Button(action: {
                stopPreview()
                var updatedSong = song
                updatedSong.startTime = startTime
                onSave(updatedSong)
            }) {
                HStack {
                    Spacer()
                    Text("Save")
                    Spacer()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
        
        // Start timer to update progress
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
            // Reset progress display when starting new playback
            currentPlayTime = startTime
            startPreview()
        }
    }
}
