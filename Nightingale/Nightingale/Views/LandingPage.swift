import SwiftUI
import SoundCloud

struct LandingPage: View {
    private let sc: SoundCloud

    enum AuthState {
        case checking
        case authenticated
        case unauthenticated
    }

    @State private var authState: AuthState = .checking
    @State private var user: User?

    init() {
        let secrets = SecretsKeeper.shared
        let config = SoundCloud.Config(
            clientId: secrets.getClientId(),
            clientSecret: secrets.getClientSecret(),
            redirectURI: secrets.getRedirectUri()
        )
        self.sc = SoundCloud(config)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.orange.opacity(0.8), .orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                content
            }
        }
        .task {
            await updateAuthState()
        }
    }

    var content: some View {
        Group {
            switch authState {
            case .checking:
                EmptyView()
            case .authenticated:
                if let user {
                    LoggedInPage(sc: sc, user: user)
                } else {
                    Text("Missing user info")
                }
            case .unauthenticated:
                WelcomeScreen(onAuthenticate: authenticateUser)
            }
        }
    }
    
    func authenticateUser() {
        Task {
            do {
                try await sc.authenticate()
                let current = try await sc.currentUser()
                user = current
                authState = .authenticated
                
            } catch {
                authState = .unauthenticated
                user = nil
                print("❌ \(error)")
            }
        }
    }
    
    func updateAuthState() async {
        do {
            user = try await sc.currentUser()
            authState = .authenticated
        } catch {
            user = nil
            authState = .unauthenticated
        }
    }
}

struct WelcomeScreen: View {
    let onAuthenticate: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.orange)
                    
                    Text("Nightingale")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Text("Game Day Music, Simplified")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "waveform",
                        title: "Curated for Hockey",
                        description: "Specially selected remixes and tracks perfect for game day moments"
                    )
                    
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
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                    .frame(height: 20)
            }
        }
        .scrollIndicators(.hidden)
    }
}

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                .background(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: .orange.opacity(0.5), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
