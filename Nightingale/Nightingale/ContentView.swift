import SwiftUI
import Foundation

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
                Color(.systemGray6)
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Welcome")
                        .font(.largeTitle).bold()

                    Text("This is a basic ContentView.")
                        .foregroundStyle(.secondary)

                    Button(action: toggleTab) {
                        Label("Toggle Tab", systemImage: selectedTab == .home ? "house" : "gearshape")
                    }
                    .buttonStyle(.borderedProminent)

                    Text("Current tab: \(selectedTab == .home ? "Home" : "Settings")")
                        .font(.callout)
                        .foregroundStyle(.secondary)

                    Group {
                        Divider().padding(.vertical, 8)
                        Text("SoundCloud Auth")
                            .font(.headline)
                        Text("Client ID: \(auth.clientID.isEmpty ? "<missing>" : auth.clientID)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        let secretMasked = auth.clientSecret.isEmpty ? "<missing>" : String(repeating: "•", count: max(4, min(12, auth.clientSecret.count)))
                        Text("Client Secret: \(secretMasked)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Text("Redirect URI: \(auth.redirectURI.isEmpty ? "<missing>" : auth.redirectURI)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
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

#Preview {
    ContentView()
}
