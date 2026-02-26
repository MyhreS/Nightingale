import SwiftUI

struct SoundCloudInfoDropdown: View {
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HapticButton(action: { withAnimation(.easeInOut(duration: 0.25)) { isExpanded.toggle() } }) {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.system(size: 13))
                    Text("What does this do?")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .foregroundStyle(Color(white: 0.45))
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    infoBullet(icon: "music.note.list", text: "We've hand-picked songs and found the perfect starting point for each one")
                    infoBullet(icon: "dollarsign.circle", text: "All songs are free — no paid SoundCloud account needed")
                    infoBullet(icon: "waveform", text: "Songs are remixes that sound very close to the originals")
                }
                .padding(.top, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func infoBullet(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(Color(red: 1.0, green: 0.33, blue: 0.0).opacity(0.7))
                .frame(width: 16)

            Text(text)
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.5))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
