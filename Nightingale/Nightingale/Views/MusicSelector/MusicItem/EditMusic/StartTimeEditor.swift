import SwiftUI

struct StartTimeEditor: View {
    let song: Song

    @State private var startTime: Double
    @State private var isPreviewPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?
    private let playerManager = PlayerManager.shared

    init(song: Song) {
        self.song = song
        _startTime = State(initialValue: song.startTime)
        _currentPlayTime = State(initialValue: song.startTime)
        print("[StartTimeEditor] 🔄 Initialized with song: \(song.fileName), startTime: \(song.startTime)")
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(song.fileName)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                HStack {
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

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 6)

                        if showProgress {
                            Capsule()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: max(0, min(geometry.size.width * (currentPlayTime / song.duration), geometry.size.width)), height: 6)
                        }

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
                        var updatedSong = song
                        updatedSong.startTime = startTime
                        print("[StartTimeEditor] ✅ Done button pressed, returning updated song")
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
            currentPlayTime = startTime
            startPreview()
        }
    }
}
