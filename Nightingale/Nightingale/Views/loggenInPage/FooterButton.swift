import SwiftUI

struct FooterButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? .white : Color(white: 0.5))
            .opacity(isSelected ? 1.0 : 0.8)
        }
        .buttonStyle(.plain)
    }
}
