import SwiftUI
import SoundCloud

struct LoggedInPage: View {
    enum Tab {
        case home
        case settings
    }
    
    let sc: SoundCloud
    @State private var selectedTab: Tab = .home
    
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            footer
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    var tabContent: some View {
        Group {
            switch selectedTab {
            case .home:
                VStack(spacing: 16) {
                    Text("Home")
                }
            case .settings:
                VStack(spacing: 16) {
                    Text("Settings")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var footer: some View {
        HStack {
            FooterButton(
                title: "Home",
                systemImage: "house.fill",
                isSelected: selectedTab == .home
            ) {
                selectedTab = .home
            }

            FooterButton(
                title: "Settings",
                systemImage: "gearshape.fill",
                isSelected: selectedTab == .settings
            ) {
                selectedTab = .settings
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundStyle(.gray.opacity(0.4)),
            alignment: .top
        )
    }
}

struct FooterButton: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .foregroundStyle(isSelected ? .orange : .gray)
        }
        .buttonStyle(.plain)
    }
}
