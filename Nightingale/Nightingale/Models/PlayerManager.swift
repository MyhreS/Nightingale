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
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            guard FileManager.default.fileExists(atPath: soundURL.path) else {
                print("❌ File not found: \(soundURL.path)")
                return
            }

            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            guard let player = audioPlayer else {
                print("❌ Failed to create audio player")
                return
            }

            player.delegate = self
            player.prepareToPlay()
            
            // Validate duration
            let duration = musicFile.duration > 0 ? musicFile.duration : player.duration
            let validStartTime = min(musicFile.startTime, duration)
            
            player.currentTime = validStartTime
            currentTime = validStartTime
            player.play()

            // Mark the song as played
            var updatedSong = musicFile
            updatedSong.played = true
            MusicLibrary.shared.updateSong(updatedSong)

            currentMusicFile = updatedSong
            isPlaying = true
            startPlaybackTimer()

            setupNowPlaying(musicFile: updatedSong)
            setupRemoteCommandCenter()

            print("🎵 Playing: \(updatedSong.name) from \(validStartTime) seconds (duration: \(duration) seconds)")
        } catch {
            print("❌ Error loading audio file: \(error.localizedDescription)")
        }
    }

    /// Preview playback for edit mode
    func previewPlay(_ musicFile: MusicFile) {
        if isPlaying { pause() } // Pause main playback if it's playing
        
        do {
            let soundURL = musicFile.url
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            previewPlayer = try AVAudioPlayer(contentsOf: soundURL)
            guard let player = previewPlayer else {
                print("❌ Failed to create preview player")
                return
            }

            player.prepareToPlay()
            
            // Validate duration and start time
            let duration = musicFile.duration > 0 ? musicFile.duration : player.duration
            let validStartTime = min(musicFile.startTime, duration)
            
            player.currentTime = validStartTime
            player.play()
            
            isPreviewPlaying = true
            
            // Start a timer to update preview state
            previewTimer?.invalidate()
            previewTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                if let player = self?.previewPlayer, player.currentTime >= duration {
                    self?.stopPreview()
                }
            }
            
            print("🎵 Preview Playing: \(musicFile.name) from \(validStartTime) seconds (duration: \(duration) seconds)")
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

    /// Finds the next song with the same tag
    private func findNextSongWithSameTag(_ currentSong: MusicFile) -> MusicFile? {
        let musicLibrary = MusicLibrary.shared
        let songsWithSameTag = musicLibrary.musicFiles.filter { $0.tag == currentSong.tag }
        
        guard let currentIndex = songsWithSameTag.firstIndex(where: { $0.id == currentSong.id }) else {
            return nil
        }
        
        // First try to find an unplayed song after the current index
        for i in (currentIndex + 1)..<songsWithSameTag.count {
            if !songsWithSameTag[i].played {
                print("🎵 Found next unplayed song with same tag: \(songsWithSameTag[i].name)")
                return songsWithSameTag[i]
            }
        }
        
        // If no unplayed songs after current index, check from start up to current index
        for i in 0..<currentIndex {
            if !songsWithSameTag[i].played {
                print("🎵 Found next unplayed song with same tag (wrapped around): \(songsWithSameTag[i].name)")
                return songsWithSameTag[i]
            }
        }
        
        // If all songs are played, get the next song in sequence
        let nextIndex = (currentIndex + 1) % songsWithSameTag.count
        if nextIndex != currentIndex {
            print("🎵 All songs played, selected next song with same tag: \(songsWithSameTag[nextIndex].name)")
            return songsWithSameTag[nextIndex]
        }
        
        return nil
    }

    /// Pauses the audio and queues the next song
    func pause() {
        audioPlayer?.pause()
        isPlaying = false
        timer?.invalidate()
        timer = nil
        updateNowPlayingPlaybackState(isPlaying: false)
        
        // Find and set next song
        if let currentSong = currentMusicFile {
            let musicLibrary = MusicLibrary.shared
            let allSongs = musicLibrary.musicFiles
            
            if !currentSong.tag.isEmpty {
                // If song has a tag, find next song with same tag
                if let nextSong = findNextSongWithSameTag(currentSong) {
                    MusicQueue.shared.addToQueue(nextSong)
                    print("🎵 Changed to next song with same tag: \(nextSong.name)")
                }
            } else {
                // If no tag, just get the next song in the library
                if let currentIndex = allSongs.firstIndex(where: { $0.id == currentSong.id }) {
                    let nextIndex = (currentIndex + 1) % allSongs.count
                    let nextSong = allSongs[nextIndex]
                    MusicQueue.shared.addToQueue(nextSong)
                    print("🎵 Changed to next song in sequence: \(nextSong.name)")
                }
            }
        }
        
        print("⏸️ Paused")
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
