import SwiftUI

struct GoalButton: View {
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "soccerball")
                    .font(.system(size: 24, weight: .bold))
                Text("Goal!")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color(white: 0.12), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(white: 0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
