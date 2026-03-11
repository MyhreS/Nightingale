import SwiftUI


struct MiniPlayerButton: View {
    let isPlaying: Bool
    let progress: Double
    let isLoading: Bool
    let isEnabled: Bool
    let errorMessage: String?
    let action: () -> Void
    @State private var loadingRotation: Double = 0
    
    private var hasError: Bool {
        !(errorMessage ?? "").isEmpty
    }
    
    private var clampedProgress: Double {
        let safeProgress = min(max(progress, 0), 1)
        if !isEnabled { return 0 }
        return safeProgress
    }

    var body: some View {
        HapticButton(action: action) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.12))
                    .frame(width: 66, height: 66)
                
                Circle()
                    .stroke(Color(white: 0.2), lineWidth: 1)
                    .frame(width: 66, height: 66)
                
                if hasError {
                    Circle()
                        .stroke(
                            Color.red.opacity(isEnabled ? 0.55 : 0.3),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round)
                        )
                        .frame(width: 66, height: 66)
                        .rotationEffect(.degrees(-90))

                    Text("!")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                } else if isLoading {
                    Circle()
                        .trim(from: 0.2, to: 0.85)
                        .stroke(
                            Color.white.opacity(isEnabled ? 0.45 : 0.28),
                            style: StrokeStyle(lineWidth: 1.8, lineCap: .round)
                        )
                        .frame(width: 66, height: 66)
                        .rotationEffect(.degrees(-90))
                        .rotationEffect(.degrees(loadingRotation))
                        .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: loadingRotation)
                } else {
                    Circle()
                        .trim(from: 0, to: clampedProgress)
                        .stroke(
                            Color.white.opacity(isEnabled ? 1 : 0.3),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 66, height: 66)
                        .rotationEffect(.degrees(-90))
                }
                
                if isLoading || hasError {
                    EmptyView()
                } else {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 31, weight: .bold))
                        .foregroundStyle(.white.opacity(isEnabled ? 1 : 0.3))
                }
            }
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 2)
            .padding(.top, 30)
            .frame(width: 70, height: 70)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .onAppear {
            if isLoading {
                loadingRotation = 360
            }
        }
        .onChange(of: isLoading) { _, newValue in
            if newValue {
                loadingRotation = 360
            } else {
                loadingRotation = 0
            }
        }
    }
}
