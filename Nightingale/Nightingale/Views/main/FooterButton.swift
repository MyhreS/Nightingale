import SwiftUI

struct FooterButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemImage)
                    .font(.system(size: 28, weight: .semibold))
                Text(title)
                    .font(.system(size: 9, weight: .medium))
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity, minHeight: 42)
            .foregroundStyle(isSelected ? .white : Color.white.opacity(isEnabled ? 0.72 : 0.32))
            .background {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(.white.opacity(0.14))
                        .overlay(
                            Capsule(style: .continuous)
                                .strokeBorder(.white.opacity(0.26), lineWidth: 1)
                        )
                        .shadow(color: .white.opacity(0.08), radius: 10, x: 0, y: -1)
                }
            }
            .opacity(isEnabled ? (isSelected ? 1.0 : 0.92) : 0.85)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
