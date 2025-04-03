
import AVFoundation
import Foundation

class AudioPlayer: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    private var timer: Timer?
    @Published var isPlaying = false

    func play(_ musicFile: Song) {
        stop()

        do {
            let soundURL = musicFile.url
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            player = try AVAudioPlayer(contentsOf: soundURL)
            guard let player = player else { return }

            player.delegate = self
            player.prepareToPlay()
            player.currentTime = musicFile.startTime
            player.play()

            isPlaying = true
            startTimer()
        } catch {
            print("[AudioPlayer] ❌ Error loading: \(error)")
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self,
                  self.isPlaying else { return }

            //if player.currentTime >= player.duration {
                //self.stop()
            //}
        }
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        self.stop()
        print("[AudioPlayer] 🎵 Finished.")
    }
}
