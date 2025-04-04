import SwiftUI

struct StartTimeEditor: View {
    @Binding var song: Song

    @Environment(\.presentationMode) private var presentationMode

    @State private var startTime: Double
    @State private var isPlaying = false
    @State private var currentPlayTime: Double
    @State private var showProgress = false
    @State private var timer: Timer?

    private var audioPlayer = AudioPlayer()

    init(song: Binding<Song>) {
        _song = song
        _startTime = State(initialValue: song.wrappedValue.startTime)
        _currentPlayTime = State(initialValue: song.wrappedValue.startTime)
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text(song.fileName)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)

                timeOverview

                sliderWithProgress

                Button(action: togglePreview) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        song.startTime = startTime
                        presentationMode.wrappedValue.dismiss()
                    }
                    .disabled(song.startTime == startTime)
                }
            }
        }
        .onDisappear {
            stopPreview()
        }
    }

    private var timeOverview: some View {
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
    }

    private var sliderWithProgress: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 6)

                if showProgress {
                    Capsule()
                        .fill(Color.green.opacity(0.7))
                        .frame(
                            width: max(0, min(geometry.size.width * (currentPlayTime / song.duration), geometry.size.width)),
                            height: 6
                        )
                }

                Slider(value: $startTime, in: 0...song.duration)
                    .accentColor(.blue)
                    .onChange(of: startTime) {
                        if isPlaying {
                            stopPreview()
                        }
                    }
            }
        }
        .frame(height: 30)
        .padding(.horizontal, 24)
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func startPreview() {
        showProgress = true
        isPlaying = true
        currentPlayTime = startTime
        var previewSong = song
        previewSong.startTime = startTime
        audioPlayer.play(previewSong)

        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if currentPlayTime < song.duration {
                currentPlayTime += 0.1
            } else {
                stopPreview()
            }
        }
    }

    private func stopPreview() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
        audioPlayer.stop()
        showProgress = false
    }

    private func togglePreview() {
        if isPlaying {
            stopPreview()
        } else {
            currentPlayTime = startTime
            startPreview()
        }
    }
}
