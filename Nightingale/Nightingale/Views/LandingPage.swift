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
                AuthenticateButton(action: authenticateUser)
                    .padding()
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

struct AuthenticateButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Authenticate")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 14)
                .padding(.horizontal, 24)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [.orange, .yellow],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}
