import SwiftUI


struct MiniPlayerButton: View {
    let isPlaying: Bool
    let progress: Double
    let action: () -> Void
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        HapticButton(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 30, weight: .bold))
                .padding(26)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.4), lineWidth: 2)
                        Circle()
                            .trim(from: 0, to: clampedProgress)
                            .stroke(
                                Color.orange,
                                style: StrokeStyle(lineWidth: 3, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                )
                .shadow(radius: 8)
        }
        .buttonStyle(.plain)
    }
}
