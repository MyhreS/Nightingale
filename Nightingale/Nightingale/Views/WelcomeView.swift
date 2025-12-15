import SwiftUI

struct WelcomeView: View {
    let onAuthenticate: () -> Void
    
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
                        icon: "speaker.wave.3.fill",
                        title: "Free with SoundCloud",
                        description: "No SoundCloud subscription needed—just a free account"
                    )
                }
                .padding(.horizontal, 24)
                
                VStack(spacing: 16) {
                    AuthenticateButton(action: onAuthenticate)
                        .padding(.horizontal, 24)
                    
                    Text("Plug and play—just log in and you're ready")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(white: 0.5))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                    .frame(height: 20)
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct AuthenticateButton: View {
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            Text("Log in with SoundCloud")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(Color.white)
                .foregroundColor(.black)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
