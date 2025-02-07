import Foundation

class MusicQueue: ObservableObject {
    static let shared = MusicQueue() // Singleton instance
    
    @Published private(set) var queue: [URL] = [] // The queue of music files (only 1 item allowed)

    private init() {}

    /// Adds a file to the queue, replacing the previous one
    func addToQueue(_ file: URL) {
        queue = [file] // ✅ Always replaces existing song
    }

    /// Clears the queue
    func clearQueue() {
        queue.removeAll()
    }

    /// Returns the only song in the queue (or nil if empty)
    var nextSong: URL? {
        return queue.first
    }
}
