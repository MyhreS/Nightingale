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
            ZStack {
                Circle()
                    .fill(.thickMaterial)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
                    .frame(width: 72, height: 72)
                
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        Color.orange,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.orange)
            }
            .shadow(color: .orange.opacity(0.4), radius: 16, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }
}
