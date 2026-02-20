import SwiftUI

struct EmailEntryView: View {
    let onContinue: (String) -> Void

    @State private var email = ""
    @FocusState private var isFocused: Bool

    private var isValidEmail: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.contains("@") && trimmed.contains(".")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)

                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Nightingale")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Game Day Music, Simplified")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(white: 0.6))
                }

                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "bolt.fill",
                        title: "Start at the Best Part",
                        description: "Songs automatically jump to the most energetic sections"
                    )

                    FeatureCard(
                        icon: "square.grid.2x2.fill",
                        title: "Organized Playlists",
                        description: "Grouped by moments: goals, warm-ups, timeouts, and more"
                    )

                    FeatureCard(
                        icon: "envelope.fill",
                        title: "Quick Setup",
                        description: "Just enter your email to get started—no password needed"
                    )
                }
                .padding(.horizontal, 24)

                VStack(spacing: 16) {
                    TextField("Email address", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isFocused)
                        .font(.system(size: 16))
                        .padding(16)
                        .background(Color(white: 0.1), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isFocused ? Color.white.opacity(0.4) : Color(white: 0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 24)

                    HapticButton(action: {
                        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        onContinue(trimmed)
                    }) {
                        Text("Continue")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 32)
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(isValidEmail ? Color.white : Color(white: 0.3))
                            .foregroundColor(isValidEmail ? .black : Color(white: 0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                    .disabled(!isValidEmail)
                    .padding(.horizontal, 24)

                    Text("We just need your email to identify you—no password required")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()
                    .frame(height: 20)
            }
        }
        .scrollIndicators(.hidden)
    }
}
