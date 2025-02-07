import Foundation

class MusicQueue: ObservableObject {
    static let shared = MusicQueue() // Singleton instance
    
    @Published private(set) var queue: [URL] = [] // The queue of music files

    private init() {}

    /// Adds a file to the queue
    func addToQueue(_ file: URL) {
        guard !queue.contains(file) else { return } // Prevent duplicates
        queue.append(file)
    }

    /// Clears the queue
    func clearQueue() {
        queue.removeAll()
    }
}
