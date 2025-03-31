import SwiftUI

enum Tab {
    case home
    case settings
}

struct ContentView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            Color(UIColor.darkGray).opacity(0.2).ignoresSafeArea()
            fadedMainContent()
            FixedBottomElements(selectedTab: $selectedTab)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    func fadedMainContent() -> some View {
        GeometryReader { geo in
            ZStack {
                switch selectedTab {
                case .home:
                    HomePage()
                case .settings:
                    SettingsPage()
                }
            }
            .mask(
                fadeMask(height: geo.size.height)
                    .frame(height: geo.size.height)
            )
        }
    }

    func fadeMask(height: CGFloat) -> LinearGradient {
        LinearGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0),
                .init(color: Color.black.opacity(0.05), location: selectedTab == .home ? 0.15 : 0.15),
                .init(color: .black, location: selectedTab == .home ? 0.25 : 0.2)
            ]),
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

struct FixedBottomElements: View {
    @Binding var selectedTab: Tab

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            if selectedTab == .home {
                MusicPlayer()
                    .padding(.horizontal)
            }
            BottomDrawer(selectedTab: $selectedTab)
                .padding(.bottom, 20)
        }
    }
}

#Preview {
    ContentView()
}
