import SwiftUI
import SoundCloud
import UniformTypeIdentifiers

struct HomePage: View {
    @StateObject private var player: MusicPlayer
    @State private var selectedPreviewSong: Song?
    @State private var selectedGroup: SongGroup = ""
    @State private var playedTimeStamps: [String: Date] = [:]
    @State private var finishedSong: Song?
    @State private var tapDebounceTask: Task<Void, Never>?
    @State private var showFilePicker = false
    @Binding var playerIsPlaying: Bool
    @Binding var playerProgress: Double
    @Binding var playerHasSong: Bool
    @Binding var playerIsLoading: Bool
    @Binding var togglePlayPauseTrigger: Bool
    @AppStorage("isAutoPlayEnabled") private var isAutoPlayEnabled = true
    @EnvironmentObject private var connectivity: Connectivity
    let songs: [Song]
    let availableGroups: [SongGroup]
    let isLoadingSongs: Bool
    let onAddLocalSong: (URL, SongGroup) -> Void
    let onDeleteSong: (Song) -> Void
    let onUpdateStartTime: (Song, Int) -> Void
    let onEditSong: (Song, String, String) -> Void
    let hasFirebaseAccess: Bool
    let isSoundCloudConnected: Bool
    let soundcloudLoginEnabled: Bool
    let onConnectSoundCloud: () -> Void

    private var hasSoundCloudSongs: Bool {
        songs.contains(where: { $0.streamingSource == .soundcloud })
    }

    var hasGoalGroup: Bool {
        availableGroups.contains { $0.lowercased() == "goal" }
    }

    var filteredSongs: [Song] {
        songs.filter { $0.group == selectedGroup }
    }

    private var visibleSongs: [Song] {
        filteredSongs.filter { song in
            connectivity.isOnline || song.streamingSource != .soundcloud
        }
    }

    private var hasHiddenSoundCloudSongsOffline: Bool {
        !connectivity.isOnline && filteredSongs.contains { $0.streamingSource == .soundcloud }
    }

    let addLocalMusicEnabled: Bool

    init(
        firebaseAPI: FirebaseAPI,
        sc: SoundCloud,
        songs: [Song],
        availableGroups: [SongGroup],
        isLoadingSongs: Bool,
        addLocalMusicEnabled: Bool,
        hasFirebaseAccess: Bool,
        isSoundCloudConnected: Bool,
        soundcloudLoginEnabled: Bool,
        playerIsPlaying: Binding<Bool>,
        playerProgress: Binding<Double>,
        playerHasSong: Binding<Bool>,
        playerIsLoading: Binding<Bool>,
        togglePlayPauseTrigger: Binding<Bool>,
        onAddLocalSong: @escaping (URL, SongGroup) -> Void,
        onDeleteSong: @escaping (Song) -> Void,
        onUpdateStartTime: @escaping (Song, Int) -> Void,
        onEditSong: @escaping (Song, String, String) -> Void,
        onConnectSoundCloud: @escaping () -> Void
    ) {
        _player = StateObject(wrappedValue: MusicPlayer(sc: sc, firebaseAPI: firebaseAPI))
        self.songs = songs
        self.availableGroups = availableGroups
        self.isLoadingSongs = isLoadingSongs
        self.addLocalMusicEnabled = addLocalMusicEnabled
        self.hasFirebaseAccess = hasFirebaseAccess
        self.isSoundCloudConnected = isSoundCloudConnected
        self.soundcloudLoginEnabled = soundcloudLoginEnabled
        _playerIsPlaying = playerIsPlaying
        _playerProgress = playerProgress
        _playerHasSong = playerHasSong
        _playerIsLoading = playerIsLoading
        _togglePlayPauseTrigger = togglePlayPauseTrigger
        self.onAddLocalSong = onAddLocalSong
        self.onDeleteSong = onDeleteSong
        self.onUpdateStartTime = onUpdateStartTime
        self.onEditSong = onEditSong
        self.onConnectSoundCloud = onConnectSoundCloud
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PageLayout(title: "Music", trailing: {
                HStack(spacing: 4) {
                    Text("powered by ")
                        .foregroundStyle(Color(white: 0.4))
                    + Text("SoundCloud")
                        .foregroundStyle(Color(red: 1.0, green: 0.33, blue: 0.0))
                    Image(systemName: "cloud.fill")
                        .foregroundStyle(Color(red: 1.0, green: 0.33, blue: 0.0))
                }
                .font(.system(size: 11, weight: .medium))
                .opacity(hasSoundCloudSongs ? 1 : 0)
                .accessibilityHidden(!hasSoundCloudSongs)
            }) {
                VStack(spacing: 16) {
                    SongGroupSelector(groups: availableGroups, selectedGroup: $selectedGroup, isLoading: isLoadingSongs)

                    if hasHiddenSoundCloudSongsOffline && isSoundCloudConnected {
                        offlineInfoCard(
                            icon: "wifi.slash",
                            title: "SoundCloud disconnected",
                            message: "Internet is required to load SoundCloud songs."
                        )
                    }

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if isLoadingSongs {
                                ForEach (0..<10, id: \.self) { _ in
                                    SongRowSkeleton()
                                }
                            } else {
                                ForEach(visibleSongs) { song in
                                    let requiresInternet = requiresInternetForPlayback(song)
                                    SongRow(
                                        song: song,
                                        isSelected: isSongSelected(song),
                                        isPlayed: isSongRecentlyPlayed(song),
                                        isDisabled: requiresInternet,
                                        statusLabel: requiresInternet ? "Internet required" : nil,
                                        onTap: {
                                            guard !requiresInternet else { return }
                                            handleSongTap(song)
                                        },
                                        onLongPress: { selectedPreviewSong = song }
                                    )
                                }

                                if !connectivity.isOnline && visibleSongs.isEmpty {
                                    offlineInfoCard(
                                        icon: "wifi.slash",
                                        title: "Internet required",
                                        message: "No offline songs found."
                                    )
                                }

                                if soundcloudLoginEnabled && !hasFirebaseAccess && !songs.contains(where: { $0.streamingSource == .soundcloud }) && songs.allSatisfy({ $0.streamingSource != .local }) {
                                    ConnectSoundCloudRow(
                                        isOnline: connectivity.isOnline,
                                        onTap: onConnectSoundCloud
                                    )
                                }

                                if addLocalMusicEnabled {
                                    AddSongRow(onTap: { showFilePicker = true })
                                }
                            }
                        }
                        .padding(.vertical, 6)
                        .padding(.bottom, 0)
                    }
                }
            }

            if let song = selectedPreviewSong {
                SongOptionsPopup(
                    song: song,
                    onClose: { selectedPreviewSong = nil },
                    onDelete: { deletedSong in
                        if player.currentSong == deletedSong {
                            player.stop()
                        }
                        onDeleteSong(deletedSong)
                    },
                    onUpdateStartTime: onUpdateStartTime,
                    onEdit: onEditSong
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }

        }
        .overlay(alignment: .bottomTrailing) {
            if hasGoalGroup && !isLoadingSongs {
                GoalButton(action: { playGoalSong() })
                    .padding(.trailing, 20)
                    .padding(.bottom, 20)
                    .zIndex(900)
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                let group = selectedGroup.isEmpty ? (availableGroups.first ?? "general") : selectedGroup
                onAddLocalSong(url, group)
            case .failure(let error):
                print("File picker error: \(error)")
            }
        }
        .onAppear {
            if selectedGroup.isEmpty, let firstGroup = availableGroups.first {
                selectedGroup = firstGroup
            }
            player.onSongFinished = { finished in
                finishedSong = finished
            }
            syncPlayerState()
        }
        .onChange(of: finishedSong) { _, song in
            guard let song else { return }
            handleSongFinished(song)
            finishedSong = nil
        }
        .onChange(of: availableGroups) { _, newGroups in
            if selectedGroup.isEmpty || !newGroups.contains(selectedGroup) {
                selectedGroup = newGroups.first ?? ""
            }
        }
        .onChange(of: player.isPlaying) { _, _ in syncPlayerState() }
        .onChange(of: player.progressFraction) { _, _ in syncPlayerState() }
        .onChange(of: player.isLoading) { _, isLoading in playerIsLoading = isLoading }
        .onChange(of: player.currentSong) { _, _ in syncPlayerState() }
        .onChange(of: togglePlayPauseTrigger) { _, triggered in
            if triggered {
                player.togglePlayPause()
                togglePlayPauseTrigger = false
            }
        }
        .onDisappear {
            player.onSongFinished = nil
        }
    }

    private func requiresInternetForPlayback(_ song: Song) -> Bool {
        guard !connectivity.isOnline else { return false }
        switch song.streamingSource {
        case .local:
            return false
        case .soundcloud:
            return true
        case .firebase:
            return !MP3Cache.shared.hasCachedSong(song)
        }
    }

    private func offlineInfoCard(icon: String, title: String, message: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(white: 0.7))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.6))
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(white: 0.18), lineWidth: 1)
        )
    }

    func playGoalSong() {
        tapDebounceTask?.cancel()

        let goalSongs = songs.filter({ $0.group.lowercased() == "goal" })
        guard !goalSongs.isEmpty else { return }
        guard let song = goalSongs.randomElement() else { return }

        playedTimeStamps[song.id] = Date()
        if let goalGroup = availableGroups.first(where: { $0.lowercased() == "goal" }) {
            selectedGroup = goalGroup
        }

        let wasPlaying = player.isPlaying
        if wasPlaying {
            player.stop()
        }

        tapDebounceTask = Task {
            if wasPlaying {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            guard !Task.isCancelled else { return }
            player.play(song: song)
        }
    }

    func handleSongTap(_ song: Song) {
        tapDebounceTask?.cancel()
        playedTimeStamps[song.id] = Date()

        let wasPlaying = player.isPlaying
        if wasPlaying {
            player.stop()
        }

        tapDebounceTask = Task {
            if wasPlaying {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
            guard !Task.isCancelled else { return }
            player.play(song: song)
        }
    }

    func isSongSelected(_ song: Song) -> Bool {
        let playerMatch = player.currentSong == song
        let lastPlayed = playedTimeStamps[song.id]
        let interval = lastPlayed.map { Date().timeIntervalSince($0) }
        let timestampMatch = interval.map { $0 < 1.0 } ?? false
        return playerMatch || timestampMatch
    }

    func isSongRecentlyPlayed(_ song: Song) -> Bool {
        guard let lastPlayed = playedTimeStamps[song.id] else { return false }
        let interval = Date().timeIntervalSince(lastPlayed)
        return interval < 3 * 60 * 60
    }

    func advanceToNextSong(after song: Song) {
        tapDebounceTask?.cancel()

        let groupSongs = songs.filter { $0.group == song.group }
        guard !groupSongs.isEmpty else { return }
        guard let index = groupSongs.firstIndex(of: song) else { return }

        let nextIndex = (index + 1) % groupSongs.count
        let nextSong = groupSongs[nextIndex]

        selectedGroup = song.group
        playedTimeStamps[nextSong.id] = Date()

        tapDebounceTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            player.play(song: nextSong)
        }
    }

    func syncPlayerState() {
        let isPlaying = player.isPlaying
        let hasSong = player.currentSong != nil
        let progress = player.progressFraction

        if playerIsPlaying != isPlaying {
            playerIsPlaying = isPlaying
        }
        if playerHasSong != hasSong {
            playerHasSong = hasSong
        }
        playerProgress = progress
    }

    func handleSongFinished(_ song: Song) {
        if isAutoPlayEnabled {
            advanceToNextSong(after: song)
        }
    }
}


struct SongRowSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(white: 0.14))
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(white: 0.16))
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(white: 0.12))
                    .frame(width: 160, height: 12)
            }

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
        .background(
            Color(white: 0.08),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(white: 0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .shimmer()
    }
}

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.0),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .rotationEffect(.degrees(18))
                        .offset(x: phase * geo.size.width * 1.5)
                        .mask(content)
                        .onAppear {
                            withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                                phase = 1
                            }
                        }
                }
            }
            .opacity(0.45)
            .allowsHitTesting(false)
    }
}

extension View {
    func shimmer() -> some View {
        modifier(Shimmer())
    }
}
