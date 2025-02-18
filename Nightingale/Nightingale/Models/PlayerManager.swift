import AVFoundation
import MediaPlayer
import Foundation

class PlayerManager: NSObject, ObservableObject { // ✅ Inherit from NSObject
    static let shared = PlayerManager() // Singleton instance
    
    private var audioPlayer: AVAudioPlayer?
    private var previewPlayer: AVAudioPlayer? // Separate player for previews
    @Published var isPlaying = false // Track play state
    @Published var isPreviewPlaying = false // Separate state for preview
    @Published var currentTime: Double = 0 // Track current playback position
    private var currentMusicFile: MusicFile?
    private var timer: Timer?
    private var previewTimer: Timer?

    /// Plays the given music file
    func play(_ musicFile: MusicFile) {
        stopPreview() // Stop any preview playback
        stop() // Stop any currently playing audio before starting a new one
        
        do {
            let soundURL = musicFile.url
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)

            guard FileManager.default.fileExists(atPath: soundURL.path) else {
                print("❌ File not found: \(soundURL.path)")
                return
            }

            // Mark the song as played
            var updatedSong = musicFile
            updatedSong.played = true
            MusicLibrary.shared.updateSong(updatedSong)

            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.currentTime = updatedSong.startTime // Use the updated song's start time
            currentTime = updatedSong.startTime
            audioPlayer?.play()

            currentMusicFile = updatedSong
            isPlaying = true
            startPlaybackTimer()

            setupNowPlaying(musicFile: updatedSong)
            setupRemoteCommandCenter()

            print("🎵 Playing: \(updatedSong.name) from \(updatedSong.startTime) seconds")
        } catch {
            print("❌ Error loading audio file: \(error.localizedDescription)")
        }
    }

    /// Preview playback for edit mode
    func previewPlay(_ musicFile: MusicFile) {
        if isPlaying { pause() } // Pause main playback if it's playing
        
        do {
            let soundURL = musicFile.url
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)

            previewPlayer = try AVAudioPlayer(contentsOf: soundURL)
            previewPlayer?.prepareToPlay()
            previewPlayer?.currentTime = musicFile.startTime
            previewPlayer?.play()
            
            isPreviewPlaying = true
            
            // Start a timer to update preview state
            previewTimer?.invalidate()
            previewTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                if let player = self?.previewPlayer, player.currentTime >= musicFile.duration {
                    self?.stopPreview()
                }
            }
            
            print("🎵 Preview Playing: \(musicFile.name) from \(musicFile.startTime) seconds")
        } catch {
            print("❌ Error loading preview audio: \(error.localizedDescription)")
        }
    }
    
    /// Stop preview playback
    func stopPreview() {
        previewPlayer?.stop()
        previewPlayer = nil
        isPreviewPlaying = false
        previewTimer?.invalidate()
        previewTimer = nil
        print("🛑 Preview Stopped")
    }

    private func startPlaybackTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, 
                  let player = self.audioPlayer, 
                  let currentFile = self.currentMusicFile,
                  self.isPlaying else { return }
            
            // If we've reached the end of the song, stop playback and queue next song
            if player.currentTime >= currentFile.duration {
                self.stop()
                self.queueNextUnplayedSong()
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
        
        // Queue next unplayed song when pausing
        queueNextUnplayedSong()
    }

    /// Stops playback completely
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = currentMusicFile?.startTime ?? 0
        timer?.invalidate()
        timer = nil
        updateNowPlayingPlaybackState(isPlaying: false)
        print("🛑 Stopped")
        
        // Queue next unplayed song
        queueNextUnplayedSong()
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

    /// Queue the next unplayed song with the same tag
    func queueNextUnplayedSong() {
        if let currentSong = currentMusicFile,
           let nextSong = MusicLibrary.shared.findNextUnplayedSong(withTag: currentSong.tag) {
            MusicQueue.shared.addToQueue(nextSong)
            print("✅ Queued next unplayed song: \(nextSong.name)")
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
