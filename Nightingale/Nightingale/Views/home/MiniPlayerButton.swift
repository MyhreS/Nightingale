import SwiftUI


struct MiniPlayerButton: View {
    let isPlaying: Bool
    let progress: Double
    let isEnabled: Bool
    let action: () -> Void
    
    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        HapticButton(action: action) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.12))
                    .frame(width: 54, height: 54)
                
                Circle()
                    .stroke(Color(white: 0.2), lineWidth: 1)
                    .frame(width: 54, height: 54)
                
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        Color.white.opacity(isEnabled ? 1 : 0.3),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 58, height: 58)
                    .rotationEffect(.degrees(-90))
                
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.3))
            }
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
