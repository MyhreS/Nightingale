import Foundation
import Combine
import AVFoundation
import AudioStreaming

struct StreamDetails {
    let url: URL
    let headers: [String: String]
}

@MainActor
final class MusicPlayer: ObservableObject, @unchecked Sendable {
    @Published var isPlaying = false
    @Published var progressSeconds: Double = 0
    @Published var durationSeconds: Double = 0
    @Published var currentSong: Song?
    
    var onSongFinished: ((Song) -> Void)?
    private var progressCancellable: AnyCancellable?
    private var currentEntryId: String?

    private let player = AudioPlayer()
    private let streamCache: StreamDetailsCache

    private var playTask: Task<Void, Never>?
    private var isAudioSessionConfigured = false
    
    private var pendingStartTime: Double?

    init(streamCache: StreamDetailsCache) {
        self.streamCache = streamCache
        player.delegate = self
    }

    func play(song: Song) {
        playTask?.cancel()
        currentSong = song
        pendingStartTime = max(0, Double(song.startSeconds))

        playTask = Task { [weak self] in
            guard let self else { return }

            do {
                let details = try await streamCache.getStreamDetails(for: song)

                if Task.isCancelled { return }

                guard details.url.pathExtension.lowercased() != "m3u8" else {
                    print("HLS (.m3u8) not supported by AudioStreaming. Use AVPlayer for this.")
                    return
                }

                configureAudioSessionIfNeeded()
                currentEntryId = details.url.absoluteString
                player.play(url: details.url, headers: details.headers)
                isPlaying = true
                startProgressUpdates()
            } catch {
                if Task.isCancelled { return }
                print("Failed to play:", error)
            }
        }
    }

    func togglePlayPause() {
        if isPlaying {
            player.pause()
            isPlaying = false
            stopProgressUpdates()
        } else {
            player.resume()
            isPlaying = true
            startProgressUpdates()
        }
    }

    func stop() {
        playTask?.cancel()
        player.stop()
        isPlaying = false
        stopProgressUpdates()
        progressSeconds = 0
        durationSeconds = 0
        currentSong = nil
        currentEntryId = nil
    }

    private func configureAudioSessionIfNeeded() {
        guard !isAudioSessionConfigured else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            isAudioSessionConfigured = true
        } catch {
            print("Audio session error:", error)
        }
    }
    
    private func startProgressUpdates() {
        if progressCancellable != nil {return}
        
        progressCancellable = Timer.publish(every: 0.25, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshProgress()
            }
    }
    
    private func stopProgressUpdates() {
        progressCancellable?.cancel()
        progressCancellable = nil
    }
    
    private func refreshProgress() {
        progressSeconds = player.progress
        durationSeconds = player.duration
    }

}

extension MusicPlayer: AudioPlayerDelegate {
    nonisolated func audioPlayerDidStartPlaying(player: AudioPlayer, with entryId: AudioEntryId) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard let t = pendingStartTime else { return }
            pendingStartTime = nil
            player.seek(to: t)
        }
    }

    nonisolated func audioPlayerStateChanged(player: AudioPlayer, with state: AudioPlayerState, previous: AudioPlayerState) {}

    nonisolated func audioPlayerDidFinishPlaying(
        player: AudioPlayer,
        entryId: AudioEntryId,
        stopReason: AudioPlayerStopReason,
        progress: Double,
        duration: Double
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard stopReason == .eof else { return }
            guard entryId.id == currentEntryId else { return }

            refreshProgress()
            isPlaying = false
            stopProgressUpdates()

            guard let finishedSong = currentSong else { return }
            onSongFinished?(finishedSong)
        }
    }

    nonisolated func audioPlayerDidFinishBuffering(player: AudioPlayer, with entryId: AudioEntryId) {}

    nonisolated func audioPlayerDidReadMetadata(player: AudioPlayer, metadata: [String : String]) {}

    nonisolated func audioPlayerDidCancel(player: AudioPlayer, queuedItems: [AudioEntryId]) {}

    nonisolated func audioPlayerUnexpectedError(player: AudioPlayer, error: AudioPlayerError) {}
}
