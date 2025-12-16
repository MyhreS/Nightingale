import SwiftUI
import SoundCloud

struct LoggedInPage: View {
    enum Tab {
        case home
        case settings
    }
    
    let sc: SoundCloud
    let streamCache: StreamDetailsCache
    @EnvironmentObject var firebaseAPI: FirebaseAPI
    
    let user: User
    let onLogOut: () -> Void
    @State private var selectedTab: Tab = .home
    @State private var songs: [Song] = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            footer
        }
        .task {
            await getSongs()
        }
        .ignoresSafeArea(edges: .bottom)
    }
    
    func getSongs() async {
        do {
            let soundcloudSongs = try await firebaseAPI.fetchSoundcloudSongs()
            let users = try await firebaseAPI.fetchUsersAllowedFirebaseSongs()
            guard users.contains(extractSoundCloudUserId(userId: user.id)) else {
                songs = soundcloudSongs
                await streamCache.preload(songs: soundcloudSongs)
                return
            }
            
            let firebaseSongs = try await firebaseAPI.fetchFirebaseSongs()
            songs = soundcloudSongs + firebaseSongs
            await streamCache.preload(songs: songs)
        } catch {
            print("Failed to fetch songs: \(error)")
        }
    }
    
    var tabContent: some View {
        Group {
            switch selectedTab {
            case .home:
                HomePage(streamCache: streamCache, songs: songs)
            case .settings:
                SettingsPage(sc: sc, user: user, onLogOut: onLogOut)
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
        .background(Color(white: 0.08))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color(white: 0.2)),
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
            .foregroundStyle(isSelected ? .white : Color(white: 0.5))
            .opacity(isSelected ? 1.0 : 0.8)
        }
        .buttonStyle(.plain)
    }
}
