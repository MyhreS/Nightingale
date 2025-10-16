import SwiftUI

enum Tab {
    case home
    case settings
}

struct ContentView: View {
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
