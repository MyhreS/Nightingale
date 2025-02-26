import Foundation

class MusicQueue: ObservableObject {
    static let shared = MusicQueue()
    
    @Published private(set) var currentSong: MusicFile?
    private var autoPlayEnabled = true

    private init() {}

    /// Adds a file to be played
    func addToQueue(_ file: MusicFile) {
        print("[MusicQueue] 🎵 Adding song to queue: \(file.name), startTime: \(file.startTime)")
        
        // Get the latest version of the song from the library to ensure we have the most up-to-date start time
        let updatedFile = getLatestSongVersion(file)
        print("[MusicQueue] 🔄 Using latest version with startTime: \(updatedFile.startTime)")
        
        // Check if this is being called from PlayerManager.pause()
        let callStack = Thread.callStackSymbols
        let isCalledFromPause = callStack.contains { $0.contains("pause") }
        
        if isCalledFromPause {
            print("[MusicQueue] ⚠️ Called from pause() - updating queue without auto-playing")
            currentSong = updatedFile
        } else {
            currentSong = updatedFile
            
            // Automatically start playing the song
            print("[MusicQueue] ▶️ Auto-playing queued song")
            PlayerManager.shared.play(updatedFile)
        }
    }
    
    /// Adds a file to the queue without auto-playing
    func addToQueueWithoutPlaying(_ file: MusicFile) {
        print("[MusicQueue] 🎵 Adding song to queue without playing: \(file.name), startTime: \(file.startTime)")
        
        // Get the latest version of the song from the library
        let updatedFile = getLatestSongVersion(file)
        print("[MusicQueue] 🔄 Using latest version with startTime: \(updatedFile.startTime)")
        
        currentSong = updatedFile
    }
    
    /// Gets the latest version of a song from the library
    private func getLatestSongVersion(_ file: MusicFile) -> MusicFile {
        // Try to find the song in the library by ID
        let musicLibrary = MusicLibrary.shared
        if let updatedSong = musicLibrary.musicFiles.first(where: { $0.id == file.id }) {
            print("[MusicQueue] 🔍 Found updated song in library with startTime: \(updatedSong.startTime)")
            return updatedSong
        }
        
        // If not found, return the original file
        print("[MusicQueue] ⚠️ Song not found in library, using original with startTime: \(file.startTime)")
        return file
    }

    /// Clears the queue
    func clearQueue() {
        print("[MusicQueue] 🧹 Clearing queue")
        currentSong = nil
    }
}
