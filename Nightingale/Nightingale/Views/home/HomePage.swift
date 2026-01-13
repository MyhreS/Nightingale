import SwiftUI
import SoundCloud

struct HomePage: View {
    @StateObject private var player: MusicPlayer
    @State private var selectedPreviewSong: Song?
    @State private var selectedGroup: SongGroup = ""
    @State private var playedTimeStamps: [String: Date] = [:]
    @State private var finishedSong: Song?
    @State private var tapDebounceTask: Task<Void, Never>?
    @Binding var playerIsPlaying: Bool
    @Binding var playerProgress: Double
    @Binding var playerHasSong: Bool
    @Binding var togglePlayPauseTrigger: Bool
    @AppStorage("isAutoPlayEnabled") private var isAutoPlayEnabled = true
    let songs: [Song]
    let isLoadingSongs: Bool
    
    var availableGroups: [SongGroup] {
        songs.uniqueGroups
    }
    
    var hasGoalGroup: Bool {
        availableGroups.contains { $0.lowercased() == "goal" }
    }
    
    var filteredSongs: [Song] {
        songs.filter { $0.group == selectedGroup }
    }

    init(
        firebaseAPI: FirebaseAPI,
        sc: SoundCloud,
        songs: [Song],
        isLoadingSongs: Bool,
        playerIsPlaying: Binding<Bool>,
        playerProgress: Binding<Double>,
        playerHasSong: Binding<Bool>,
        togglePlayPauseTrigger: Binding<Bool>
    ) {
        _player = StateObject(wrappedValue: MusicPlayer(sc: sc, firebaseAPI: firebaseAPI))
        self.songs = songs
        self.isLoadingSongs = isLoadingSongs
        _playerIsPlaying = playerIsPlaying
        _playerProgress = playerProgress
        _playerHasSong = playerHasSong
        _togglePlayPauseTrigger = togglePlayPauseTrigger
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PageLayout(title: "Music") {
                HStack(spacing: 4) {
                    Text("powered by")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("SoundCloud")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(red: 1.0, green: 0.33, blue: 0.0))
                }
                .opacity(0.8)
            } content: {
                VStack(spacing: 16) {
                    SongGroupSelector(groups: availableGroups, selectedGroup: $selectedGroup, isLoading: isLoadingSongs)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if isLoadingSongs {
                                ForEach (0..<10, id: \.self) { _ in
                                    SongRowSkeleton()
                                }
                            } else {
                                ForEach(filteredSongs) { song in
                                    SongRow(
                                        song: song,
                                        isSelected: isSongSelected(song),
                                        isPlayed: isSongRecentlyPlayed(song),
                                        onTap: { handleSongTap(song) },
                                        onLongPress: { selectedPreviewSong = song }
                                    )
                                }
                            }
                            
                            
                        }
                        .padding(.vertical, 6)
                        .padding(.bottom, 160)
                    }
                }
            }

            if let song = selectedPreviewSong {
                SongPreview(
                    song: song,
                    onClose: { selectedPreviewSong = nil }
                )
                .transition(.scale.combined(with: .opacity))
                .zIndex(1000)
            }

        }
        .overlay(alignment: .bottomTrailing) {
            if hasGoalGroup && !isLoadingSongs {
                GoalButton(action: { playGoalSong() })
                    .padding(.trailing, 20)
                    .padding(.bottom, 100)
                    .zIndex(900)
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
        .onChange(of: songs) { _, newSongs in
            if selectedGroup.isEmpty || !newSongs.contains(where: { $0.group == selectedGroup }) {
                selectedGroup = newSongs.uniqueGroups.first ?? ""
            }
        }
        .onChange(of: player.isPlaying) { _, _ in syncPlayerState() }
        .onChange(of: player.progressFraction) { _, _ in syncPlayerState() }
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
        playerIsPlaying = player.isPlaying
        playerProgress = player.progressFraction
        playerHasSong = player.currentSong != nil
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
