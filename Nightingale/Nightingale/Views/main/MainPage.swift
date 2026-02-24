import SwiftUI
import SoundCloud

struct MainPage: View {
    enum Tab { case home, settings }

    let sc: SoundCloud
    @EnvironmentObject var firebaseAPI: FirebaseAPI
    @AppStorage("userEmail") private var email = ""

    @StateObject private var vm = MainViewModel()
    @State private var scUser: User?
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
            await firebaseAPI.fetchFeatureFlags()
            await tryRefreshSCAuth()
            await vm.loadSongs(
                firebaseAPI: firebaseAPI,
                email: firebaseAPI.emailLoginEnabled ? email : "",
                scAuthenticated: scUser != nil && firebaseAPI.soundcloudLoginEnabled
            )
        }
        .onChange(of: email) { _, newEmail in
            Task {
                await vm.loadSongs(
                    firebaseAPI: firebaseAPI,
                    email: firebaseAPI.emailLoginEnabled ? newEmail : "",
                    scAuthenticated: scUser != nil && firebaseAPI.soundcloudLoginEnabled
                )
            }
        }
        .onChange(of: vm.hasFirebaseAccess) { _, hasAccess in
            if hasAccess && scUser != nil {
                disconnectSoundCloud()
            }
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
                        availableGroups: vm.availableGroups,
                        isLoadingSongs: vm.isLoadingSongs,
                        addLocalMusicEnabled: firebaseAPI.addLocalMusicEnabled,
                        playerIsPlaying: $playerIsPlaying,
                        playerProgress: $playerProgress,
                        playerHasSong: $playerHasSong,
                        togglePlayPauseTrigger: $togglePlayPauseTrigger,
                        onAddLocalSong: { url, group in
                            Task { await vm.addLocalSong(from: url, group: group) }
                        },
                        onDeleteSong: { song in
                            vm.deleteLocalSong(song)
                        },
                        onUpdateStartTime: { song, seconds in
                            vm.updateLocalSongStartTime(song: song, startSeconds: seconds)
                        },
                        onEditSong: { song, name, artist in
                            vm.updateLocalSongName(song: song, name: name)
                            vm.updateLocalSongArtist(song: song, artist: artist)
                        }
                    )
                } else {
                    ErrorLoadingSongsView()
                }
            case .settings:
                SettingsPage(
                    sc: sc,
                    scUser: scUser,
                    hasFirebaseAccess: vm.hasFirebaseAccess,
                    onConnectSoundCloud: connectSoundCloud,
                    onDisconnectSoundCloud: disconnectSoundCloud
                )
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

    private func tryRefreshSCAuth() async {
        do {
            scUser = try await sc.currentUser()
        } catch {
            scUser = nil
        }
    }

    private func connectSoundCloud() {
        Task {
            do {
                try await sc.authenticate()
                scUser = try await sc.currentUser()
                await vm.loadSongs(
                    firebaseAPI: firebaseAPI,
                    email: email,
                    scAuthenticated: true
                )
            } catch {
                print("SoundCloud auth failed: \(error)")
            }
        }
    }

    private func disconnectSoundCloud() {
        sc.signOut()
        scUser = nil
        Task {
            await vm.loadSongs(
                firebaseAPI: firebaseAPI,
                email: email,
                scAuthenticated: false
            )
        }
    }
}
