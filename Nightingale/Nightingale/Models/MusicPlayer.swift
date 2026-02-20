import Foundation
import Combine
import AVFoundation
import AudioStreaming
import SoundCloud
import MediaPlayer

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

    private var playTask: Task<Void, Never>?
    private var isAudioSessionConfigured = false
    
    private var pendingStartTime: Double?
    private var effectiveStartTime: Double = 0
    
    private var sc: SoundCloud
    private var firebaseAPI: FirebaseAPI
    
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
        
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: song.originalSongName.isEmpty ? song.name : song.originalSongName,
            MPMediaItemPropertyArtist: song.originalSongArtistName.isEmpty ? song.artistName : song.originalSongArtistName,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: adjustedProgressSeconds,
            MPMediaItemPropertyPlaybackDuration: adjustedDurationSeconds,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        let artworkURLString = song.originalArtWorkUrl.isEmpty ? song.artworkURL : song.originalArtWorkUrl
        if let artworkURL = URL(string: artworkURLString),
           let cachedImage = ImageCache.shared[artworkURL] {
            let artwork = MPMediaItemArtwork(boundsSize: cachedImage.size) { _ in cachedImage }
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    func play(song: Song) {
        playTask?.cancel()
        currentEntryId = nil
        
        progressSeconds = 0
        durationSeconds = 0
        currentSong = song
        effectiveStartTime = max(0, Double(song.startSeconds))
        pendingStartTime = effectiveStartTime

        playTask = Task { [weak self] in
            guard let self else { return }

            do {
                let details = try await fetchStreamDetails(song: song)

                if Task.isCancelled { return }

                guard details.url.pathExtension.lowercased() != "m3u8" else {
                    print("HLS (.m3u8) not supported by AudioStreaming. Use AVPlayer for this.")
                    return
                }

                configureAudioSessionIfNeeded()
                player.play(url: details.url, headers: details.headers)
                isPlaying = true
                startProgressUpdates()
                updateNowPlayingInfo()
            } catch {
                if Task.isCancelled { return }
                print("Failed to play:", error)
            }
        }
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
            let cache = MP3Cache.shared
            let localURL = cache.cachedURL(for: song)
            
            if cache.hasCachedSong(song) {
                return StreamDetails(url: localURL, headers: [:])
            }
            
            let url = try await firebaseAPI.fetchStorageDownloadURL(path: song.songId)
            return StreamDetails(url: url, headers: [:])

        case .local:
            let fileURL = LocalSongStore.shared.fileURL(for: song)
            return StreamDetails(url: fileURL, headers: [:])
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
        updateNowPlayingInfo()
    }

    func stop() {
        playTask?.cancel()
        player.stop()
        isPlaying = false
        stopProgressUpdates()
        progressSeconds = 0
        durationSeconds = 0
        effectiveStartTime = 0
        currentSong = nil
        currentEntryId = nil
        updateNowPlayingInfo()
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
        updateNowPlayingInfo()
    }

}

extension MusicPlayer: AudioPlayerDelegate {
    nonisolated func audioPlayerDidStartPlaying(player: AudioPlayer, with entryId: AudioEntryId) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            currentEntryId = entryId.id
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
            
            let minPlaybackDuration: Double = 10.0
            guard progress >= minPlaybackDuration else {
                isPlaying = false
                stopProgressUpdates()
                return
            }

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
