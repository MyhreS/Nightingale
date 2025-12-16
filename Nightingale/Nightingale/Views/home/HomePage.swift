import SwiftUI

struct HomePage: View {
    @StateObject private var player: MusicPlayer
    @State private var selectedPreviewSong: Song?
    @State private var selectedGroup: SongGroup = .faceoff
    @State private var playedTimeStamps: [String: Date] = [:]
    let songs: [Song]
    let isLoadingSongs: Bool
    
    var filteredSongs: [Song] {
        songs.filter { $0.group == selectedGroup }
    }

    init(streamCache: StreamDetailsCache, songs: [Song], isLoadingSongs: Bool) {
        _player = StateObject(wrappedValue: MusicPlayer(streamCache: streamCache))
        self.songs = songs
        self.isLoadingSongs = isLoadingSongs
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PageLayout(title: "Music") {
                VStack(spacing: 16) {
                    SongGroupSelector(groups: SongGroup.allCases, selectedGroup: $selectedGroup)
                    
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
                        .padding(.bottom, 70)
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

            if player.currentSong != nil {
                MiniPlayerButton(
                    isPlaying: player.isPlaying,
                    progress: player.progressFraction,
                    action: { player.togglePlayPause() }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 100)
                .zIndex(900)
            }
            
        }
        .overlay(alignment: .bottomLeading) {
            GoalButton(action: { playGoalSong() })
                .padding(.leading, 20)
                .padding(.bottom, 100)
                .zIndex(900)
        }
        .overlay(alignment: .bottomTrailing) {
            if player.currentSong != nil {
                MiniPlayerButton(
                    isPlaying: player.isPlaying,
                    progress: player.progressFraction,
                    action: { player.togglePlayPause() }
                )
                .padding(.trailing, 20)
                .padding(.bottom, 100)
                .zIndex(900)
            }
        }
        .onAppear {
            player.onSongFinished = { finished in
                advanceToNextSong(after: finished)
            }
        }
        .onDisappear {
            player.onSongFinished = nil
        }
    }
    
    func playGoalSong() {
        let goalSongs = songs.filter({ $0.group == .goal })
        guard !goalSongs.isEmpty else { return }
        
        guard let song = goalSongs.randomElement() else {return}
        player.play(song: song)
        playedTimeStamps[song.id] = Date()
        selectedGroup = .goal
    }

    func handleSongTap(_ song: Song) {
        player.play(song: song)
        playedTimeStamps[song.id] = Date()
    }
    
    func isSongSelected(_ song: Song) -> Bool {
        if player.currentSong == song {
            return true
        }
        
        guard let lastPlayed = playedTimeStamps[song.id] else { return false }
        let interval = Date().timeIntervalSince(lastPlayed)
        return interval < 1.0
    }
    
    func isSongRecentlyPlayed(_ song: Song) -> Bool {
        guard let lastPlayed = playedTimeStamps[song.id] else { return false }
        let interval = Date().timeIntervalSince(lastPlayed)
        return interval < 3 * 60 * 60
    }

    func advanceToNextSong(after song: Song) {
        let groupSongs = songs.filter { $0.group == song.group }
        guard !groupSongs.isEmpty else { return }
        guard let index = groupSongs.firstIndex(of: song) else { return }

        let nextIndex = (index + 1) % groupSongs.count
        let nextSong = groupSongs[nextIndex]

        selectedGroup = song.group
        playedTimeStamps[nextSong.id] = Date()
        player.play(song: nextSong)
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
