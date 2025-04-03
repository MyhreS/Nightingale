import SwiftUI

struct MusicPlayer: View {
    //@ObservedObject private var playerManager = PlayerManager.shared

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                PlayStopToggleButton()
            }
            .frame(maxWidth: .infinity, maxHeight: 40)

            VStack(spacing: 4) {
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 2)
                }
                .frame(height: 2)
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
        }
        .padding(6)
        .background(
            Color(uiColor: .darkGray)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.4), lineWidth: 1)
        )
    }

    private func formatTime(_ time: Double) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
