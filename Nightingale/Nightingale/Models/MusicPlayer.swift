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
                player.play(url: finalURL, headers: details.headers)
                isPlaying = true
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
        } else {
            player.resume()
            isPlaying = true
        }
    }

    func stop() {
        playTask?.cancel()
        player.stop()
        isPlaying = false
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
        final class RedirectCatcher: NSObject, URLSessionTaskDelegate {
            var redirectedURL: URL?

            func urlSession(
                _ session: URLSession,
                task: URLSessionTask,
                willPerformHTTPRedirection response: HTTPURLResponse,
                newRequest request: URLRequest,
                completionHandler: @escaping (URLRequest?) -> Void
            ) {
                redirectedURL = request.url
                completionHandler(nil)
            }
        }

        let delegate = RedirectCatcher()
        let session = URLSession(configuration: .ephemeral, delegate: delegate, delegateQueue: nil)

        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        headers.forEach { req.setValue($0.value, forHTTPHeaderField: $0.key) }

        _ = try await session.data(for: req)

        if let redirected = delegate.redirectedURL {
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

}

extension MusicPlayer: AudioPlayerDelegate {
    func audioPlayerDidStartPlaying(player: AudioPlayer, with entryId: AudioEntryId) {
        guard let t = pendingStartTime else {return}
        pendingStartTime = nil
        player.seek(to: t)
    }
    
    func audioPlayerStateChanged(player: AudioPlayer, with state: AudioPlayerState, previous: AudioPlayerState) {}
    func audioPlayerDidFinishPlaying(
        player: AudioPlayer,
        entryId: AudioEntryId,
        stopReason: AudioPlayerStopReason,
        progress: Double,
        duration: Double
    ) {}
    
    func audioPlayerDidFinishBuffering(player: AudioPlayer, with entryId: AudioEntryId) {}

    func audioPlayerDidReadMetadata(player: AudioPlayer, metadata: [String : String]) {}

    func audioPlayerDidCancel(player: AudioPlayer, queuedItems: [AudioEntryId]) {}

    func audioPlayerUnexpectedError(player: AudioPlayer, error: AudioPlayerError) {}
}
