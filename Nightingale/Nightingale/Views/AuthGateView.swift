import SwiftUI
import SoundCloud

struct AuthGateView: View {
    let sc: SoundCloud

    enum AuthState {
        case checking
        case authenticated
        case unauthenticated
    }

    @State private var authState: AuthState = .checking
    @State private var user: User?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
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
                    LoggedInPage(sc: sc, user: user, onLogOut: logOut)
                } else {
                    Text("Missing user info")
                }
            case .unauthenticated:
                WelcomeView(onAuthenticate: authenticateUser)
            }
        }
    }
    
    func logOut() {
        sc.signOut()
        authState = .unauthenticated
        user = nil
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
