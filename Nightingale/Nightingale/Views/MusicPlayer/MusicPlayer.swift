import SwiftUI

struct MusicPlayer: View {
    @ObservedObject private var playerManager = PlayerManager.shared
    @ObservedObject private var musicQueue = MusicQueue.shared
    
    var body: some View {
        CustomCard {
            VStack(spacing: 8) {
                // Main controls
                HStack(spacing: 10) {
                    CurrentQueued()
                    PlayPauseButton()
                }
                .frame(maxWidth: .infinity, maxHeight: 70)
                
                // Timeline
                VStack(spacing: 4) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background track
                            Capsule()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 4)
                            
                            // Progress
                            if let currentSong = musicQueue.nextSong {
                                // Start time indicator (filled portion before start)
                                Capsule()
                                    .fill(Color.blue.opacity(0.3))
                                    .frame(width: geometry.size.width * (currentSong.startTime / currentSong.duration), height: 4)
                                
                                // Current progress
                                Capsule()
                                    .fill(Color.blue)
                                    .frame(width: max(0, min(geometry.size.width * (playerManager.currentTime / currentSong.duration), geometry.size.width)), height: 4)
                            }
                        }
                    }
                    .frame(height: 4)
                    
                    // Time labels
                    HStack {
                        Text(formatTime(playerManager.currentTime))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .monospacedDigit()
                        
                        Spacer()
                        
                        Text(formatTime(musicQueue.nextSong?.duration ?? 0))
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .monospacedDigit()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
        }
        .padding(10)
    }
    
    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
