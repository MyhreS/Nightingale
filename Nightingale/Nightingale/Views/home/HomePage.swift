import SwiftUI

struct HomePage: View {
    @StateObject private var player: MusicPlayer
    @State private var selectedPreviewSong: Song?
    @State private var selectedGroup: SongGroup = .faceoff
    @State private var playedTimeStamps: [String: Date] = [:]
    let songs: [Song]
    
    var filteredSongs: [Song] {
        songs.filter { $0.group == selectedGroup }
    }

    init(streamCache: StreamDetailsCache, songs: [Song]) {
        _player = StateObject(wrappedValue: MusicPlayer(streamCache: streamCache))
        self.songs = songs
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            PageLayout(title: "Music") {
                VStack(spacing: 16) {
                    SongGroupSelector(groups: SongGroup.allCases, selectedGroup: $selectedGroup)
                    
                    ScrollView {
                        LazyVStack(spacing: 10) {
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
