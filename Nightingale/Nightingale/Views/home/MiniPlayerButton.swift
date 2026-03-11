import SwiftUI


struct MiniPlayerButton: View {
    let isPlaying: Bool
    let progress: Double
    let isEnabled: Bool
    let isErrorVisible: Bool
    let errorMessage: String?
    let action: () -> Void
    @State private var iconGlowPhase = false
    
    private var hasError: Bool {
        isErrorVisible && !(errorMessage ?? "").isEmpty
    }

    private var buttonLabel: String {
        isPlaying ? "Pause" : "Play"
    }

    private let activeGlowColor = Color(red: 0.35, green: 0.75, blue: 0.45)

    private var iconColor: Color {
        activeGlowColor.opacity(iconGlowPhase ? 1 : 0.88)
    }

    private var iconShadowColor: Color {
        activeGlowColor.opacity(iconGlowPhase ? 0.28 : 0.16)
    }

    var body: some View {
        HapticButton(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    if hasError {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(Color.red.opacity(isEnabled ? 0.95 : 0.5))
                    } else {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(iconColor)
                            .shadow(color: iconShadowColor, radius: 9, x: 0, y: 0)
                            .animation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true), value: iconGlowPhase)
                    }
                }

                Text(buttonLabel)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color.white.opacity(isEnabled ? 0.72 : 0.72))
            }
            .frame(maxWidth: .infinity, minHeight: 42)
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 8)
            .opacity(1)
        }
        .buttonStyle(.plain)
        .onAppear {
            iconGlowPhase = true
        }
    }
}
