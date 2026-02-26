import SwiftUI

struct ConnectSoundCloudRow: View {
    let onTap: () -> Void

    private let scOrange = Color(red: 1.0, green: 0.33, blue: 0.0)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(scOrange.opacity(0.12))
                        .frame(width: 52, height: 52)

                    Image(systemName: "cloud.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(scOrange)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Connect SoundCloud")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("Get ready-to-play songs for your games")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(white: 0.45))
                }

                Spacer(minLength: 12)

                HapticButton(action: onTap) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(scOrange)
                }
                .buttonStyle(.plain)
            }

            SoundCloudInfoDropdown()
                .padding(.leading, 66)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
        .background(
            Color(white: 0.08),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(scOrange.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}
