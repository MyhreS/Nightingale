import Foundation
import SoundCloud
import Combine
import AVFoundation

@MainActor
final class MusicPlayer: ObservableObject, @unchecked Sendable {
    @Published var currentSong: PredefinedSong?
    @Published var isPlaying = false
    @Published var progress: Double = 0

    var onSongFinished: ((PredefinedSong) -> Void)?

    private let sc: SoundCloud
    private var player: AVPlayer?
    private var endObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var timeObserver: Any?
    private var startOffsetSeconds: Double = 0
    private var isAudioSessionConfigured = false

    init(sc: SoundCloud) {
        self.sc = sc
    }

    func play(song: PredefinedSong) {
        print("Playing song \(song.name)")
        Task {
            await playAsync(song: song, startAt: Double(song.startSeconds))
        }
    }

    func togglePlayPause() {
        guard let player else { return }

        if isPlaying {
            player.pause()
            isPlaying = false
        } else {
            player.play()
            isPlaying = true
        }
    }

    func seekTo(seconds: Double) {
        guard let player = player else { return }
        let time = CMTime(seconds: seconds, preferredTimescale: 1_000)
        player.seek(to: time)
    }

    private func playAsync(song: PredefinedSong, startAt seconds: Double) async {
        stopAndCleanup()
        
        currentSong = song
        isPlaying = false
        progress = 0
        
        if !isAudioSessionConfigured {
            configureAudioSession()
            isAudioSessionConfigured = true
        }

        do {
            let url: URL
            let headers: [String: String]
            
            if let cached = StreamURLCache.shared.getURL(for: song.id) {
                print("MusicPlayer: using cached URL for \(song.name)")
                url = cached.url
                headers = cached.headers
            } else {
                print("MusicPlayer: fetching fresh URL for \(song.name)")
                let streamInfo = try await sc.streamInfo(for: song.id)
                let fetchedHeaders = try await sc.authorizationHeader
                
                guard let fetchedUrl = URL(string: streamInfo.httpMp3128URL) ?? URL(string: streamInfo.hlsMp3128URL) else {
                    print("MusicPlayer: invalid stream URLs")
                    return
                }
                
                url = fetchedUrl
                headers = fetchedHeaders
                StreamURLCache.shared.setURL(for: song.id, url: url, headers: headers)
            }

            prepareAndStartPlayback(url: url, song: song, headers: headers, startAt: seconds)
        } catch {
            print("MusicPlayer: failed to start playback: \(error)")
        }
    }

    private func prepareAndStartPlayback(
        url: URL,
        song: PredefinedSong,
        headers: [String: String],
        startAt seconds: Double
    ) {
        print("🎵 prepareAndStartPlayback for \(song.name)")
        print("   - startAt: \(seconds) seconds")
        startOffsetSeconds = seconds

        let asset = AVURLAsset(
            url: url,
            options: ["AVURLAssetHTTPHeaderFieldsKey": headers]
        )
        let item = AVPlayerItem(asset: asset)
        setupPlayer(with: item)

        if seconds != 0 {
            print("⏭️ Seeking to \(seconds) seconds")
            let time = CMTime(seconds: seconds, preferredTimescale: 1_000)
            player?.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
                print("🎯 Seek completed: finished=\(finished)")
                Task { @MainActor [weak self] in
                    self?.startPlayback()
                }
            }
        } else {
            print("▶️ No seek needed, starting immediately")
            startPlayback()
        }
    }
    
    private func setupPlayer(with item: AVPlayerItem) {
        removeObservers()
        
        print("�� setupPlayer called")

        statusObserver = item.observe(\.status, options: [.initial, .new]) { item, _ in
            switch item.status {
            case .readyToPlay:
                print("✅ MusicPlayer: item ready to play")
            case .failed:
                print("❌ MusicPlayer: item failed: \(String(describing: item.error))")
            case .unknown:
                print("❓ MusicPlayer: item status unknown")
            @unknown default:
                print("❓ MusicPlayer: item status unknown default")
            }
        }

        let player = AVPlayer(playerItem: item)
        player.automaticallyWaitsToMinimizeStalling = false  // ADD THIS LINE
        self.player = player
        
        print("�� New player created, automaticallyWaitsToMinimizeStalling: \(player.automaticallyWaitsToMinimizeStalling)")

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handlePlaybackEnded()
            }
        }

        let interval = CMTime(seconds: 0.2, preferredTimescale: 600)
        timeObserver = player.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self, weak player] time in
            Task { @MainActor [weak self, weak player] in
                guard let self,
                      let player,
                      let currentItem = player.currentItem
                else {
                    return
                }

                let durationSeconds = currentItem.duration.seconds
                guard durationSeconds.isFinite, durationSeconds > 0 else {
                    self.progress = 0
                    return
                }

                let effectiveDuration = max(durationSeconds - self.startOffsetSeconds, 1)
                let current = max(time.seconds - self.startOffsetSeconds, 0)
                let raw = current / effectiveDuration
                self.progress = min(max(raw, 0), 1)
            }
        }
    }

    private func startPlayback() {
        guard let player = player else {
            print("⚠️ startPlayback: player is nil")
            return
        }
        
        guard let currentItem = player.currentItem else {
            print("⚠️ startPlayback: currentItem is nil")
            return
        }
        
        print("▶️ startPlayback: attempting to play")
        print("   - item status: \(currentItem.status.rawValue)")
        print("   - player rate: \(player.rate)")
        print("   - player timeControlStatus: \(player.timeControlStatus.rawValue)")
        print("   - current time: \(player.currentTime().seconds)")
        
        if currentItem.status != .readyToPlay {
            print("⚠️ startPlayback: item not ready, status = \(currentItem.status)")
            return
        }
        
        player.play()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self, weak player] in
            guard let player = player else { return }
            print("✅ After play() - rate: \(player.rate), timeControlStatus: \(player.timeControlStatus.rawValue)")
            
            if player.rate == 0 && player.timeControlStatus != .playing {
                print("🔴 PLAYBACK DID NOT START! Forcing play again...")
                player.play()
            }
            
            self?.isPlaying = player.rate > 0
        }
    }

    private func handlePlaybackEnded() {
        let finishedSong = currentSong
        isPlaying = false
        if let finishedSong {
            onSongFinished?(finishedSong)
        }
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

    private func stopAndCleanup() {
        print("🛑 stopAndCleanup called")
        if let player = player {
            print("   - player rate before pause: \(player.rate)")
            player.pause()
            print("   - player paused")
        }
        removeObservers()
        player = nil
        startOffsetSeconds = 0
        print("   - cleanup complete")
    }

    private func removeObservers() {
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
            self.endObserver = nil
        }
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        statusObserver = nil
    }
}
