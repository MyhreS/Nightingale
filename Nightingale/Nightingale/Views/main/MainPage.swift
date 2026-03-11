import SwiftUI
import SoundCloud

struct MainPage: View {
    enum Tab { case home, settings }

    let sc: SoundCloud
    @EnvironmentObject var firebaseAPI: FirebaseAPI
    @EnvironmentObject var connectivity: Connectivity
    @AppStorage("userEmail") private var email = ""

    @StateObject private var vm = MainViewModel()
    @State private var scUser: User?
    @State private var selectedTab: Tab = .home
    @State private var playerIsPlaying = false
    @State private var playerProgress: Double = 0
    @State private var playerHasSong = false
    @State private var playerIsLoading = false
    @State private var playerErrorMessage: String? = nil
    @State private var showPlayerErrorForDuration = false
    @State private var errorFlashTask: Task<Void, Never>?
    @State private var togglePlayPauseTrigger = false
    @State private var stopPlaybackTrigger = false
    @State private var playGoalTrigger = false

    private var hasGoalGroup: Bool {
        vm.availableGroups.contains { $0.lowercased() == "goal" }
    }

    var body: some View {
        tabContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                footer
            }
        .task {
            await firebaseAPI.fetchFeatureFlags()
            await tryRefreshSCAuth()

            if !firebaseAPI.soundcloudLoginEnabled && scUser != nil {
                sc.signOut()
                scUser = nil
            }

            if !firebaseAPI.emailLoginEnabled && !email.isEmpty {
                email = ""
            }

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
        .onAppear {
            triggerPlayerErrorFlash(for: playerErrorMessage)
        }
        .onChange(of: playerErrorMessage) { _, message in
            triggerPlayerErrorFlash(for: message)
        }
        .onDisappear {
            errorFlashTask?.cancel()
        }
    }

    private var tabContent: some View {
        ZStack {
            Group {
                if !vm.errorWhenLoadingSongs {
                    HomePage(
                        firebaseAPI: firebaseAPI,
                        sc: sc,
                        songs: vm.songs,
                        availableGroups: vm.availableGroups,
                        isLoadingSongs: vm.isLoadingSongs,
                        addLocalMusicEnabled: firebaseAPI.addLocalMusicEnabled,
                        hasFirebaseAccess: vm.hasFirebaseAccess,
                        isSoundCloudConnected: scUser != nil,
                        soundcloudLoginEnabled: firebaseAPI.soundcloudLoginEnabled,
                        playerIsPlaying: $playerIsPlaying,
                        playerProgress: $playerProgress,
                        playerHasSong: $playerHasSong,
                        playerIsLoading: $playerIsLoading,
                        playerErrorMessage: $playerErrorMessage,
                        stopPlaybackTrigger: $stopPlaybackTrigger,
                        playGoalTrigger: $playGoalTrigger,
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
                        },
                        onConnectSoundCloud: connectSoundCloud
                    )
                } else {
                    ErrorLoadingSongsView()
                }
            }
            .opacity(selectedTab == .home ? 1 : 0)
            .allowsHitTesting(selectedTab == .home)

            SettingsPage(
                sc: sc,
                scUser: scUser,
                hasFirebaseAccess: vm.hasFirebaseAccess,
                onConnectSoundCloud: connectSoundCloud,
                onDisconnectSoundCloud: disconnectSoundCloud
            )
            .opacity(selectedTab == .settings ? 1 : 0)
            .allowsHitTesting(selectedTab == .settings)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.28), radius: 22, x: 0, y: 12)
                .shadow(color: .white.opacity(0.06), radius: 10, x: 0, y: -1)

            HStack(spacing: 4) {
                FooterButton(
                    title: "Home",
                    systemImage: "house.fill",
                    isSelected: selectedTab == .home,
                    isEnabled: true
                ) { selectedTab = .home }

                FooterButton(
                    title: "Settings",
                    systemImage: "gearshape.fill",
                    isSelected: selectedTab == .settings,
                    isEnabled: true
                ) { selectedTab = .settings }

                FooterButton(
                    title: "Goal!",
                    systemImage: "soccerball",
                    isSelected: false,
                    isEnabled: hasGoalGroup
                ) {
                    selectedTab = .home
                    playGoalTrigger = true
                }

                MiniPlayerButton(
                    isPlaying: playerIsPlaying,
                    progress: playerProgress,
                    isEnabled: true,
                    isErrorVisible: showPlayerErrorForDuration,
                    errorMessage: playerErrorMessage,
                    action: {
                        if playerIsLoading {
                            stopPlaybackTrigger = true
                        } else {
                            togglePlayPauseTrigger = true
                        }
                    }
                )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 70)
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color.clear)
        .ignoresSafeArea(edges: .bottom)
    }

    private func tryRefreshSCAuth() async {
        do {
            scUser = try await sc.currentUser()
        } catch {
            scUser = nil
        }
    }

    private func connectSoundCloud() {
        guard connectivity.isOnline else { return }
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

    private func triggerPlayerErrorFlash(for message: String?) {
        errorFlashTask?.cancel()
        errorFlashTask = nil

        guard let message, !message.isEmpty else {
            showPlayerErrorForDuration = false
            return
        }

        showPlayerErrorForDuration = true
        let snapshot = message
        errorFlashTask = Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            if Task.isCancelled { return }
            if playerErrorMessage == snapshot {
                showPlayerErrorForDuration = false
            }
        }
    }
}
