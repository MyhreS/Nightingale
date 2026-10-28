import Foundation
import Combine
import AVFoundation
import AudioStreaming
import SoundCloud
import MediaPlayer
import SwiftUI

struct StreamDetails {
    let url: URL
    let headers: [String: String]
}

@MainActor
final class MusicPlayer: NSObject, ObservableObject, @unchecked Sendable {
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var loadingProgress: Double = 0
    @Published var playbackError: String? = nil
    @Published var progressSeconds: Double = 0
    @Published var durationSeconds: Double = 0
    @Published var currentSong: Song?
    
    var onSongFinished: ((Song) -> Void)?
    var onPlaybackError: ((String?) -> Void)?
    private var progressCancellable: AnyCancellable?
    private var currentEntryId: String?
    private let progressUpdateInterval: TimeInterval = 0.1

    private let player = AudioPlayer()
    private var localPlayer: AVAudioPlayer?

    private var playTask: Task<Void, Never>?
    private var loadingProgressTask: Task<Void, Never>?
    private var isAudioSessionConfigured = false
    private var hasStartedStreamingPlayback = false

    private var pendingStartTime: Double?
    private var effectiveStartTime: Double = 0

    private var fadeTask: Task<Void, Never>?
    private let fadeInDuration: TimeInterval = 0.15
    private var cachingSongIds = Set<String>()
    
    private var sc: SoundCloud
    private var firebaseAPI: FirebaseAPI

    private func reportError(_ message: String, error: Error? = nil) {
        ErrorReporter.shared.report(message, context: "playback", song: currentSong, error: error)
        stop(shouldClearPlaybackError: false)
        playbackError = message
        onPlaybackError?(message)
    }

    private func clearPlaybackError() {
        playbackError = nil
        onPlaybackError?(nil)
    }
    
    var adjustedProgressSeconds: Double {
        max(0, progressSeconds - effectiveStartTime)
    }
    
    var adjustedDurationSeconds: Double {
        max(0, durationSeconds - effectiveStartTime)
    }
    
    var progressFraction: Double {
        guard adjustedDurationSeconds > 0 else { return 0 }
        return min(max(adjustedProgressSeconds / adjustedDurationSeconds, 0), 1)
    }

    init(sc: SoundCloud, firebaseAPI: FirebaseAPI) {
        self.sc = sc
        self.firebaseAPI = firebaseAPI
        super.init()
        player.delegate = self
        setupRemoteCommands()
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if !self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            if self.isPlaying {
                self.togglePlayPause()
            }
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self else { return .commandFailed }
            self.togglePlayPause()
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        let displayArtist = song.streamingSource == .soundcloud
            ? "Remixed by: \(song.artistName)"
            : song.artistName

        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.name,
            MPMediaItemPropertyArtist: displayArtist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: adjustedProgressSeconds,
            MPMediaItemPropertyPlaybackDuration: adjustedDurationSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let artworkURL = URL(string: song.artworkURL),
           let cachedImage = ImageCache.shared[artworkURL] {
            let artwork = MPMediaItemArtwork(boundsSize: cachedImage.size) { _ in cachedImage }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func play(song: Song) {
        playTask?.cancel()
        cancelFade()
        let shouldPreserveLoadingState = isLoading && currentSong == song
        if !shouldPreserveLoadingState {
            beginLoadingIndicator(for: song)
        }
        stopLocalPlayer()
        player.stop()
        currentEntryId = nil
        hasStartedStreamingPlayback = false

        if song.streamingSource == .local {
            playFile(at: LocalSongStore.shared.fileURL(for: song))
            return
        }

        if song.streamingSource == .firebase && MP3Cache.shared.hasCachedSong(song) {
            playFile(at: MP3Cache.shared.cachedURL(for: song))
            return
        }

        playTask = Task { [weak self] in
            guard let self else { return }

            do {
                let details = try await fetchStreamDetails(song: song)

                if Task.isCancelled { return }

                guard details.url.pathExtension.lowercased() != "m3u8" else {
                    print("HLS (.m3u8) not supported by AudioStreaming. Use AVPlayer for this.")
                    self.isLoading = false
                    self.reportError("Unsupported stream format (.m3u8).")
                    return
                }

                if song.streamingSource == .firebase {
                    cacheInBackground(song, from: details.url)
                }

                configureAudioSessionIfNeeded()
                // Muted until the seek to startSeconds lands; audioPlayerDidStartPlaying fades it in.
                player.volume = 0
                player.play(url: details.url, headers: details.headers)
                isPlaying = true
                startProgressUpdates()
                updateNowPlayingInfo()
            } catch {
                if Task.isCancelled { return }
                self.isLoading = false
                if let accessError = error as? FirebaseAccessError {
                    self.firebaseAPI.presentAccessAlert(for: accessError)
                }
                print("Failed to play:", error)
                self.reportError("Failed to start playback: \(error.localizedDescription)", error: error)
            }
        }
    }

    private func playFile(at fileURL: URL) {
        isLoading = false
        stopLoadingProgressAnimation()
        loadingProgress = 0
        clearPlaybackError()

        do {
            configureAudioSessionIfNeeded()
            localPlayer = try AVAudioPlayer(contentsOf: fileURL)
            localPlayer?.delegate = self
            localPlayer?.prepareToPlay()

            if effectiveStartTime > 0 {
                localPlayer?.currentTime = effectiveStartTime
            }

            localPlayer?.volume = 0
            localPlayer?.play()
            localPlayer?.setVolume(1, fadeDuration: fadeInDuration)
            durationSeconds = localPlayer?.duration ?? 0
            pendingStartTime = nil
            isPlaying = true
            isLoading = false
            stopLoadingProgressAnimation()
            startProgressUpdates()
            updateNowPlayingInfo()
        } catch {
            isLoading = false
            stopLoadingProgressAnimation()
            loadingProgress = 0
            reportError("Failed to play file: \(error.localizedDescription)", error: error)
            print("Failed to play local file:", error)
        }
    }

    private func stopLocalPlayer() {
        localPlayer?.stop()
        localPlayer = nil
    }

    private func cacheInBackground(_ song: Song, from remoteURL: URL) {
        guard !cachingSongIds.contains(song.songId) else { return }
        cachingSongIds.insert(song.songId)

        Task { [weak self] in
            do {
                try await MP3Cache.shared.cacheSong(song, from: remoteURL)
            } catch {
                print("Failed to cache song \(song.id):", error)
                ErrorReporter.shared.report("Failed to cache song", context: "cache", song: song, error: error)
            }
            self?.cachingSongIds.remove(song.songId)
        }
    }

    /// Fades the streaming player in once playback has reached `startTime`, so neither the
    /// pre-seek audio nor the hard cut into the waveform is audible.
    private func fadeInStreamingPlayer(after startTime: Double?) {
        fadeTask?.cancel()
        fadeTask = Task { @MainActor [weak self] in
            guard let self else { return }

            if let startTime, startTime > 0 {
                let deadline = Date().addingTimeInterval(1.5)
                while player.progress < startTime - 0.25 && Date() < deadline {
                    try? await Task.sleep(nanoseconds: 20_000_000)
                    if Task.isCancelled { return }
                }
            }

            let steps = 15
            for step in 1...steps {
                try? await Task.sleep(nanoseconds: UInt64(fadeInDuration / Double(steps) * 1_000_000_000))
                if Task.isCancelled { return }
                player.volume = Float(step) / Float(steps)
            }
        }
    }

    private func cancelFade() {
        fadeTask?.cancel()
        fadeTask = nil
    }
    
    private func fetchStreamDetails(song: Song) async throws -> StreamDetails {
        switch song.streamingSource {
        case .soundcloud:
            let streamInfo = try await sc.streamInfo(for: song.songId)
            let headers = try await sc.authorizationHeader
            
            guard let url = URL(string: streamInfo.httpMp3128URL) ?? URL(string: streamInfo.hlsMp3128URL) else {
                throw URLError(.badURL)
            }
            return StreamDetails(url: url, headers: headers)
            
        case .firebase:
            let url = try await firebaseAPI.fetchStorageDownloadURL(path: song.songId)
            return StreamDetails(url: url, headers: [:])

        case .local:
            fatalError("Local songs use AVAudioPlayer, not the streaming path")
        }
    }

    func togglePlayPause() {
        if isPlaying {
            cancelFade()
            if localPlayer != nil {
                localPlayer?.pause()
            } else {
                player.pause()
            }
            isPlaying = false
            isLoading = false
            clearPlaybackError()
            stopProgressUpdates()
        } else {
            if localPlayer != nil {
                localPlayer?.volume = 0
                localPlayer?.play()
                localPlayer?.setVolume(1, fadeDuration: fadeInDuration)
            } else {
                player.volume = 0
                player.resume()
                fadeInStreamingPlayer(after: nil)
            }
            isPlaying = true
            isLoading = false
            clearPlaybackError()
            startProgressUpdates()
        }
        updateNowPlayingInfo()
    }

    func stop(shouldClearPlaybackError: Bool = true) {
        playTask?.cancel()
        cancelFade()
        stopLoadingProgressAnimation()
        stopLocalPlayer()
        player.stop()
        isPlaying = false
        isLoading = false
        loadingProgress = 0
        hasStartedStreamingPlayback = false
        if shouldClearPlaybackError {
            clearPlaybackError()
        }
        stopProgressUpdates()
        progressSeconds = 0
        durationSeconds = 0
        effectiveStartTime = 0
        currentSong = nil
        currentEntryId = nil
        updateNowPlayingInfo()
    }

    func beginLoadingIndicator(for song: Song) {
        stopLoadingProgressAnimation()
        isPlaying = false
        isLoading = true
        loadingProgress = 0.08
        clearPlaybackError()
        progressSeconds = 0
        durationSeconds = 0
        currentSong = song
        effectiveStartTime = max(0, Double(song.startSeconds))
        pendingStartTime = effectiveStartTime
        startLoadingProgressAnimation()
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
            reportError("Audio session error: \(error.localizedDescription)", error: error)
        }
    }
    
    private func startProgressUpdates() {
        if progressCancellable != nil {return}
        
        progressCancellable = Timer.publish(every: progressUpdateInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshProgress()
            }
    }
    
    private func stopProgressUpdates() {
        progressCancellable?.cancel()
        progressCancellable = nil
    }

    private func startLoadingProgressAnimation() {
        loadingProgressTask?.cancel()
        loadingProgressTask = Task { @MainActor [weak self] in
            guard let self else { return }

            let milestones: [(target: Double, delay: UInt64)] = [
                (0.18, 160_000_000),
                (0.30, 180_000_000),
                (0.42, 220_000_000),
                (0.54, 260_000_000),
                (0.63, 320_000_000),
                (0.70, 420_000_000),
            ]

            for milestone in milestones {
                while isLoading && loadingProgress < milestone.target {
                    try? await Task.sleep(nanoseconds: milestone.delay)
                    guard !Task.isCancelled, isLoading else { return }
                    let step = max(0.018, (milestone.target - loadingProgress) * 0.6)
                    withAnimation(.easeOut(duration: 0.22)) {
                        self.loadingProgress = min(milestone.target, self.loadingProgress + step)
                    }
                }
            }
        }
    }

    private func stopLoadingProgressAnimation() {
        loadingProgressTask?.cancel()
        loadingProgressTask = nil
    }

    private func completeLoadingIndicatorQuickly() {
        stopLoadingProgressAnimation()
        withAnimation(.easeOut(duration: 0.14)) {
            self.loadingProgress = 1
        }

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 150_000_000)
            guard let self else { return }
            guard hasStartedStreamingPlayback else { return }
            isLoading = false
        }
    }
    
    private func refreshProgress() {
        if let lp = localPlayer {
            progressSeconds = lp.currentTime
            durationSeconds = lp.duration
        } else {
            progressSeconds = player.progress
            durationSeconds = player.duration
        }

        if localPlayer == nil && !hasStartedStreamingPlayback && progressSeconds > 0 {
                hasStartedStreamingPlayback = true
                completeLoadingIndicatorQuickly()
        }
        updateNowPlayingInfo()
    }

}

extension MusicPlayer: AudioPlayerDelegate {
    nonisolated func audioPlayerDidStartPlaying(player: AudioPlayer, with entryId: AudioEntryId) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            currentEntryId = entryId.id
            clearPlaybackError()
            let startTime = pendingStartTime
            pendingStartTime = nil
            if let startTime, startTime > 0 {
                player.seek(to: startTime)
            }
            fadeInStreamingPlayer(after: startTime)
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
            
            let minPlaybackDuration: Double = 10.0
            guard progress >= minPlaybackDuration else {
                isPlaying = false
                isLoading = false
                stopLoadingProgressAnimation()
                loadingProgress = 0
                stopProgressUpdates()
                return
            }

            refreshProgress()
            isPlaying = false
            isLoading = false
            stopLoadingProgressAnimation()
            loadingProgress = 0
            stopProgressUpdates()

            guard let finishedSong = currentSong else { return }
            onSongFinished?(finishedSong)
        }
    }

    nonisolated func audioPlayerDidFinishBuffering(player: AudioPlayer, with entryId: AudioEntryId) {}

    nonisolated func audioPlayerDidReadMetadata(player: AudioPlayer, metadata: [String : String]) {}

    nonisolated func audioPlayerDidCancel(player: AudioPlayer, queuedItems: [AudioEntryId]) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            isLoading = false
            reportError("Playback was cancelled.")
        }
    }

    nonisolated func audioPlayerUnexpectedError(player: AudioPlayer, error: AudioPlayerError) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            isLoading = false
            reportError("Unexpected playback error: \(error)")
        }
    }
}

extension MusicPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            guard flag else { return }
            isPlaying = false
            isLoading = false
            stopProgressUpdates()
            guard let finishedSong = currentSong else { return }
            onSongFinished?(finishedSong)
        }
    }
}
