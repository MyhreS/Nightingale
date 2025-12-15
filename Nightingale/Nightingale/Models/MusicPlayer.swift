import Foundation
import SoundCloud
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
    @Published var currentSong: PredefinedSong?
    
    var onSongFinished: ((PredefinedSong) -> Void)?
    private var progressCancellable: AnyCancellable?
    private var currentEntryId: String?

    private let player = AudioPlayer()
    private let sc: SoundCloud

    private var playTask: Task<Void, Never>?
    private var isAudioSessionConfigured = false
    
    private var pendingStartTime: Double?

    init(sc: SoundCloud) {
        self.sc = sc
        player.delegate = self
    }

    func play(song: PredefinedSong) {
        playTask?.cancel()
        currentSong = song
        pendingStartTime = max(0, Double(song.startSeconds))

        playTask = Task { [weak self] in
            guard let self else { return }

            do {
                let details = try await getSongStreamDetails(song: song)
                let finalURL = try await resolveRedirectedURL(url: details.url, headers: details.headers)

                if Task.isCancelled { return }

                guard finalURL.pathExtension.lowercased() != "m3u8" else {
                    print("HLS (.m3u8) not supported by AudioStreaming. Use AVPlayer for this.")
                    return
                }

                configureAudioSessionIfNeeded()
                currentEntryId = finalURL.absoluteString
                player.play(url: finalURL, headers: details.headers)
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

    private func getSongStreamDetails(song: PredefinedSong) async throws -> StreamDetails {
        if let cached = StreamURLCache.shared.getURL(for: song.id) {
            return StreamDetails(url: cached.url, headers: cached.headers)
        }

        let streamInfo = try await sc.streamInfo(for: song.id)
        let headers = try await sc.authorizationHeader

        guard let url = URL(string: streamInfo.httpMp3128URL) ?? URL(string: streamInfo.hlsMp3128URL) else {
            throw URLError(.badURL)
        }

        let details = StreamDetails(url: url, headers: headers)
        StreamURLCache.shared.setURL(for: song.id, url: url, headers: headers)
        return details
    }

    private func resolveRedirectedURL(url: URL, headers: [String: String]) async throws -> URL {
        final class RedirectCatcher: NSObject, URLSessionTaskDelegate, @unchecked Sendable {
            private let lock = NSLock()
            private var redirectedURLStorage: URL?

            func urlSession(
                _ session: URLSession,
                task: URLSessionTask,
                willPerformHTTPRedirection response: HTTPURLResponse,
                newRequest request: URLRequest,
                completionHandler: @escaping (URLRequest?) -> Void
            ) {
                setRedirectedURL(request.url)
                completionHandler(nil)
            }

            func setRedirectedURL(_ url: URL?) {
                lock.lock()
                redirectedURLStorage = url
                lock.unlock()
            }

            func redirectedURL() -> URL? {
                lock.lock()
                let url = redirectedURLStorage
                lock.unlock()
                return url
            }
        }

        let delegate = RedirectCatcher()
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }

        _ = try await session.data(for: req)

        if let redirected = delegate.redirectedURL() {
            return redirected
        }

        return url
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
