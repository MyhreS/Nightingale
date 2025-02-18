import AVFoundation
import MediaPlayer
import Foundation

class PlayerManager: NSObject, ObservableObject { // ✅ Inherit from NSObject
    static let shared = PlayerManager() // Singleton instance
    
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false // Track play state
    @Published var currentTime: Double = 0 // Track current playback position
    private var currentMusicFile: MusicFile?
    private var timer: Timer?

    /// Plays the given music file
    func play(_ musicFile: MusicFile) {
        stop() // Stop any currently playing audio before starting a new one
        
        do {
            let soundURL = musicFile.url
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)

            guard FileManager.default.fileExists(atPath: soundURL.path) else {
                print("❌ File not found: \(soundURL.path)")
                return
            }

            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.currentTime = musicFile.startTime // Set the start time
            currentTime = musicFile.startTime // Set initial current time
            audioPlayer?.play()

            currentMusicFile = musicFile
            isPlaying = true
            startPlaybackTimer()

            setupNowPlaying(musicFile: musicFile) // Setup Now Playing info
            setupRemoteCommandCenter() // Enable lock screen controls

            print("🎵 Playing: \(musicFile.name) from \(musicFile.startTime) seconds")
        } catch {
            print("❌ Error loading audio file: \(error.localizedDescription)")
        }
    }

    private func startPlaybackTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, 
                  let player = self.audioPlayer, 
                  let currentFile = self.currentMusicFile,
                  self.isPlaying else { return }
            
            // If we've reached the end of the song, stop playback
            if player.currentTime >= currentFile.duration {
                self.stop()
                return
            }
            
            self.currentTime = player.currentTime
        }
    }

    /// Toggles between play and pause
    func togglePlayback(for musicFile: MusicFile) {
        if isPlaying {
            pause()
        } else {
            play(musicFile)
        }
    }

    /// Pauses the audio
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
        timer = nil
        updateNowPlayingPlaybackState(isPlaying: false)
        print("⏸️ Paused")
    }

    /// Stops playback completely
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = currentMusicFile?.startTime ?? 0 // Reset to start time instead of 0
        timer?.invalidate()
        timer = nil
        updateNowPlayingPlaybackState(isPlaying: false)
        print("🛑 Stopped")
    }

    /// Setup Now Playing Info (lock screen & Control Center)
    private func setupNowPlaying(musicFile: MusicFile) {
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: musicFile.name,
            MPNowPlayingInfoPropertyPlaybackRate: 1.0
        ]

        if let duration = audioPlayer?.duration {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer?.currentTime ?? 0
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    /// Updates playback state on the lock screen
    private func updateNowPlayingPlaybackState(isPlaying: Bool) {
        var nowPlayingInfo = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioPlayer?.currentTime ?? 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    /// Setup Remote Command Center for lock screen controls
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            if let musicFile = self?.currentMusicFile {
                self?.play(musicFile)
            }
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.stopCommand.isEnabled = true
        commandCenter.stopCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
    }
}

extension PlayerManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        updateNowPlayingPlaybackState(isPlaying: false)
        print("🎵 Playback finished.")
    }
}
