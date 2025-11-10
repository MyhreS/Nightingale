import SwiftUI


struct MiniPlayerButton: View {
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 30, weight: .bold))
                .padding(26)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                )
                .shadow(radius: 8)
        }
        .buttonStyle(.plain)
    }
}
