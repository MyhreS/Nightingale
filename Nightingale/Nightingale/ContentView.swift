import SwiftUI

enum Tab {
    case home
    case settings
}

struct ContentView: View {
    @StateObject private var auth = SoundCloudAuth.shared
    @State private var selectedTab: Tab = .home

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 16) {
                    Text("Welcome").font(.largeTitle).bold()
                    Text("This is a basic ContentView.").foregroundStyle(.secondary)
                    Button(action: toggleTab) {
                        Label("Toggle Tab", systemImage: selectedTab == .home ? "house" : "gearshape")
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        auth.startAuthorizationWithASWebAuth()
                    } label: {
                        Label("Log in with SoundCloud", systemImage: "person.crop.circle.badge.checkmark")
                    }
                    .buttonStyle(.bordered)
                    Text("Current tab: \(selectedTab == .home ? "Home" : "Settings")")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Group {
                        Divider().padding(.vertical, 8)
                        Text("SoundCloud Auth").font(.headline)
                        Text("Client ID: \(auth.clientID.isEmpty ? "<missing>" : auth.clientID)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Text("Client Secret: \(auth.clientSecret.isEmpty ? "<missing>" : String(repeating: "•", count: max(4, min(12, auth.clientSecret.count))))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Redirect URI: \(auth.redirectURI.isEmpty ? "<missing>" : auth.redirectURI)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Text("Access Token: \(maskToken(auth.accessToken))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Expires At: \(format(auth.expiresAt))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .navigationTitle("Content")
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
