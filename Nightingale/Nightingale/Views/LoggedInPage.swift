import SwiftUI
import SoundCloud

struct LoggedInPage: View {
    enum Tab {
        case home
        case settings
    }
    
    let sc: SoundCloud
    let user: User
    @State private var selectedTab: Tab = .home
    @State private var hasPrefetchedURLs = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            footer
        }
        .ignoresSafeArea(edges: .bottom)
        .onAppear {
            prefetchStreamURLs()
        }
    }
    
    func prefetchStreamURLs() {
        guard !hasPrefetchedURLs else { return }
        hasPrefetchedURLs = true
        
        Task {
            let songs = PredefinedSongStore.loadPredefinedSongs()
            await StreamURLCache.shared.prefetchAll(songs: songs, using: sc)
        }
    }
    
    var tabContent: some View {
        Group {
            switch selectedTab {
            case .home:
                HomePage(sc: sc)
            case .settings:
                SettingsPage(sc: sc, user: user)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    var footer: some View {
        HStack(spacing: 0) {
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
        .padding(.horizontal, 32)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity)
        .background(.thickMaterial)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.gray.opacity(0.5)),
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
        HapticButton(action: action) {
            VStack(spacing: 6) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isSelected ? .orange : .secondary)
            .opacity(isSelected ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
    }
}
