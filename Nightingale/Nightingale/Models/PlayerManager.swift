import AVFoundation
import Foundation

class PlayerManager: ObservableObject {
    static let shared = PlayerManager() // Singleton instance
    
    private var audioPlayer: AVAudioPlayer?
    @Published var isPlaying = false // Track play state

    /// Plays the given music file from a specific position (in seconds)
    func play(_ musicFile: MusicFile, from time: TimeInterval = 0.0) {
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
            audioPlayer?.prepareToPlay()
            audioPlayer?.currentTime = time // ✅ Start playback from a specific time
            audioPlayer?.play()
            isPlaying = true
            print("🎵 Playing: \(musicFile.name) from \(time) sec")
        } catch {
            print("❌ Error loading audio file: \(error.localizedDescription)")
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
        print("⏸️ Paused")
    }

    /// Stops playback completely
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        print("🛑 Stopped")
    }
}
