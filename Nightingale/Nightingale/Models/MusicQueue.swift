import Foundation

class MusicQueue: ObservableObject {
    static let shared = MusicQueue()
    
    @Published private(set) var currentSong: MusicFile?

    private init() {}

    /// Adds a file to be played
    func addToQueue(_ file: MusicFile) {
        currentSong = file
    }

    /// Clears the queue
    func clearQueue() {
        currentSong = nil
    }
}
