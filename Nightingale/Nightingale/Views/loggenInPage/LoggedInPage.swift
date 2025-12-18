import SwiftUI
import SoundCloud

struct LoggedInPage: View {
    enum Tab { case home, settings }

    let sc: SoundCloud
    @EnvironmentObject var firebaseAPI: FirebaseAPI

    let user: User
    let onLogOut: () -> Void

    @StateObject private var vm = LoggedInViewModel()
    @State private var selectedTab: Tab = .home
    @State private var playerIsPlaying = false
    @State private var playerProgress: Double = 0
    @State private var playerHasSong = false
    @State private var togglePlayPauseTrigger = false

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            footer
        }
        .task {
            await vm.loadSongs(firebaseAPI: firebaseAPI, user: user)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var tabContent: some View {
        Group {
            switch selectedTab {
            case .home:
                if !vm.errorWhenLoadingSongs {
                    HomePage(
                        firebaseAPI: firebaseAPI,
                        sc: sc,
                        songs: vm.songs,
                        isLoadingSongs: vm.isLoadingSongs,
                        playerIsPlaying: $playerIsPlaying,
                        playerProgress: $playerProgress,
                        playerHasSong: $playerHasSong,
                        togglePlayPauseTrigger: $togglePlayPauseTrigger
                    )
                } else {
                    ErrorLoadingSongsView()
                }
            case .settings:
                SettingsPage(sc: sc, user: user, onLogOut: onLogOut)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack(spacing: 0) {
            FooterButton(
                title: "Home",
                systemImage: "house.fill",
                isSelected: selectedTab == .home
            ) { selectedTab = .home }

            if selectedTab == .home {
                MiniPlayerButton(
                    isPlaying: playerIsPlaying,
                    progress: playerProgress,
                    isEnabled: playerHasSong,
                    action: { togglePlayPauseTrigger = true }
                )
            }

            FooterButton(
                title: "Settings",
                systemImage: "gearshape.fill",
                isSelected: selectedTab == .settings
            ) { selectedTab = .settings }
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

