import SwiftUI

enum Tab {
    case home
    case settings
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            Color(UIColor.darkGray).opacity(0.3)
                .ignoresSafeArea()

            // Page content
            Group {
                switch selectedTab {
                case .home:
                    HomePage()
                case .settings:
                    SettingsPage()
                }
            }

            // Fixed bottom elements
            VStack(spacing: 0) {
                Spacer()
                if selectedTab == .home {
                    MusicPlayer()
                        .padding(.horizontal)
                        .padding(.bottom, 0)
                }

                BottomDrawer(selectedTab: $selectedTab)
                    .padding(.bottom, 20)
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

#Preview {
    ContentView()
}
