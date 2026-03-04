import SwiftUI

struct ConnectSoundCloudRow: View {
    let isOnline: Bool
    let onTap: () -> Void

    private let scOrange = Color(red: 1.0, green: 0.33, blue: 0.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(scOrange)

                Text("SoundCloud")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(isOnline ? "Get ready-to-play songs" : "Internet required")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.5))
            }

            SoundCloudInfoDropdown()

            if !isOnline {
                Text("Connect requires internet access.")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.6))
            }

            HapticButton(action: onTap) {
                HStack(spacing: 8) {
                    Image(systemName: "link.badge.plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Connect")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(maxWidth: .infinity)
                .background(scOrange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(scOrange.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!isOnline)
        }
        .padding(16)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(scOrange.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
