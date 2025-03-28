import SwiftUI

struct MusicPlayer: View {
    @ObservedObject private var playerManager = PlayerManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                //CurrentQueued()
                //PlayPauseButton()
                PlayStopToggleButton()
            }
            .frame(maxWidth: .infinity, maxHeight: 70)

            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .frame(height: 4)

                HStack {
                    Text(formatTime(playerManager.currentTime))
                        .font(.caption2)
                        .foregroundColor(.white)
                        .monospacedDigit()
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .padding()
        .background(
            Color.gray.opacity(0.5)
                .clipShape(RoundedRectangle(cornerRadius: 30)) // keep blur inside
        )
        .clipShape(RoundedRectangle(cornerRadius: 30)) // keep child views within shape too
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1.5)
        )
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
