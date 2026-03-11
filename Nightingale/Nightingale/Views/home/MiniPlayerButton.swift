import SwiftUI


struct MiniPlayerButton: View {
    let isPlaying: Bool
    let progress: Double
    let isEnabled: Bool
    let isErrorVisible: Bool
    let errorMessage: String?
    let action: () -> Void
    @State private var glowPhaseIndex = 0
    
    private var hasError: Bool {
        isErrorVisible && !(errorMessage ?? "").isEmpty
    }

    private var buttonLabel: String {
        isPlaying ? "Pause" : "Play"
    }

    private let activeGlowColor = Color(red: 0.35, green: 0.75, blue: 0.45)
    private let warmGlowColor = Color(red: 1.0, green: 0.82, blue: 0.60)
    private let coolGlowColor = Color(red: 0.72, green: 0.86, blue: 1.0)
    private let subtleGlowColor = Color(red: 0.70, green: 0.92, blue: 0.70)

    private var iconColor: Color {
        switch glowPhaseIndex {
        case 1:
            return warmGlowColor
        case 2:
            return coolGlowColor
        case 3:
            return subtleGlowColor
        default:
            return .white.opacity(0.78)
        }
    }

    private var iconShadowColor: Color {
        switch glowPhaseIndex {
        case 1:
            return Color.orange.opacity(0.09)
        case 2:
            return Color.blue.opacity(0.10)
        case 3:
            return activeGlowColor.opacity(0.12)
        default:
            return .white.opacity(0.04)
        }
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
                            .shadow(color: iconShadowColor, radius: 6, x: 0, y: 0)
                            .animation(.easeInOut(duration: 0.9), value: glowPhaseIndex)
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
            startGlowCycle()
        }
    }

    private func startGlowCycle() {
        guard glowPhaseIndex == 0 else { return }

        Task { @MainActor in
            while true {
                try? await Task.sleep(nanoseconds: 900_000_000)
                glowPhaseIndex = (glowPhaseIndex + 1) % 4
            }
        }
    }
}
