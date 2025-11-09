import Foundation
import SoundCloud
import Combine
import AVFoundation

final class MusicPlayer: ObservableObject {
    @Published var currentSong: PredefinedSong?
    @Published var isPlaying = false

    private let sc: SoundCloud
    private var player: AVPlayer?
    private var endObserver: Any?
    private var statusObserver: NSKeyValueObservation?

    init(sc: SoundCloud) {
        self.sc = sc
        configureAudioSession()
    }

    deinit {
        removeEndObserver()
        removeStatusObserver()
    }

    func play(song: PredefinedSong) {
        Task {
            await playAsync(song: song, 15)
        }
    }

    func togglePlayPause() {
        Task { @MainActor in
            guard let player else { return }
            if isPlaying {
                player.pause()
                isPlaying = false
            } else {
                player.play()
                isPlaying = true
            }
        }
    }

    private func playAsync(song: PredefinedSong, startAt seconds: Double? = nil) async {
        do {
            let streamInfo = try await sc.streamInfo(for: song.id)
            let headers = try await sc.authorizationHeader

            guard let url = streamUrl(from: streamInfo) else {
                print("MusicPlayer: could not extract stream URL from StreamInfo")
                return
            }

            await prepareAndStartPlayback(url: url, song: song, headers: headers, startAt: seconds)
        } catch {
            print("MusicPlayer: failed to start playback: \(error)")
        }
    }

    private func streamUrl(from streamInfo: StreamInfo) -> URL? {
        if let url = URL(string: streamInfo.httpMp3128URL) {
            return url
        }
        if let url = URL(string: streamInfo.hlsMp3128URL) {
            return url
        }
        return nil
    }

    @MainActor
    private func prepareAndStartPlayback(
        url: URL,
        song: PredefinedSong,
        headers: [String : String],
        startAt seconds: Double?
    ) {
        currentSong = song
        let options: [String: Any] = ["AVURLAssetHTTPHeaderFieldsKey": headers]
        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        setUpPlayer(with: item)

        if let seconds {
            let time = CMTime(seconds: seconds, preferredTimescale: 1_000)
            player?.seek(to: time) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.startPlayback()
                }
            }
        } else {
            startPlayback()
        }
    }

    @MainActor
    private func setUpPlayer(with item: AVPlayerItem) {
        removeEndObserver()
        removeStatusObserver()

        statusObserver = item.observe(\.status, options: [.initial, .new]) { item, _ in
            switch item.status {
            case .readyToPlay:
                print("MusicPlayer: ready to play")
            case .failed:
                print("MusicPlayer: item failed: \(String(describing: item.error))")
            case .unknown:
                print("MusicPlayer: item status unknown")
            @unknown default:
                print("MusicPlayer: item status unknown default")
            }
        }

        let player = AVPlayer(playerItem: item)
        self.player = player

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.handlePlaybackEnded()
        }
    }

    @MainActor
    private func startPlayback() {
        guard let player else { return }
        player.play()
        isPlaying = true
    }

    @MainActor
    private func handlePlaybackEnded() {
        isPlaying = false
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("MusicPlayer: audio session error: \(error)")
        }
    }

    private func removeEndObserver() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
    }

    private func removeStatusObserver() {
        statusObserver = nil
    }
}
