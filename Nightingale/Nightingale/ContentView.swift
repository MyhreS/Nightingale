import SwiftUI

enum Tab {
    case home
    case settings
}

struct ContentView: View {
    @StateObject private var auth = SoundCloudAuth.shared
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        if (auth.isAuthenticated) {
            LandingPage()
        } else {
            LoginPage(onLogin: auth.startAuthorizationWithASWebAuth)
            
        }
        
    }
    

    private func toggleTab() {
        selectedTab = (selectedTab == .home) ? .settings : .home
    }
}

private func maskToken(_ token: String?) -> String {
    guard let t = token, !t.isEmpty else { return "<none>" }
    let start = t.prefix(6)
    let end = t.suffix(4)
    return "\(start)…\(end)"
}

private func format(_ date: Date?) -> String {
    guard let d = date else { return "<unknown>" }
    let f = ISO8601DateFormatter()
    f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return f.string(from: d)
}

#Preview {
    ContentView()
}
