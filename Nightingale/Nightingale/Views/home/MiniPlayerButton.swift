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
                .font(.system(size: 32, weight: .bold))
                .frame(width: 72, height: 72)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .overlay(
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 2.5)
                        Circle()
                            .trim(from: 0, to: clampedProgress)
                            .stroke(
                                Color.orange,
                                style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                    }
                )
                .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
