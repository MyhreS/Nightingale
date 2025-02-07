import Foundation
import UniformTypeIdentifiers

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary() // Singleton instance

    @Published private(set) var musicFiles: [URL] = []

    private let storageKey = "SavedMusicFiles"

    private init() {
        loadMusicFiles()
    }

    /// Adds a new music file and saves it persistently (prevents duplicates)
    func addMusicFile(_ url: URL) -> Bool {
        guard !musicFiles.contains(url) else {
            print("File already exists: \(url.lastPathComponent)")
            return false // ✅ Return false if duplicate
        }
        musicFiles.append(url)
        saveMusicFiles()
        return true // ✅ Return true if successfully added
    }

    /// Removes a music file and updates storage
    func removeMusicFile(_ url: URL) {
        musicFiles.removeAll { $0 == url }
        saveMusicFiles()
    }

    /// Clears all stored music files
    func clearMusicLibrary() {
        musicFiles.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Saves the music file URLs persistently
    private func saveMusicFiles() {
        let savedPaths = musicFiles.map { $0.path }
        UserDefaults.standard.set(savedPaths, forKey: storageKey)
    }

    /// Loads stored music file paths
    private func loadMusicFiles() {
        if let savedPaths = UserDefaults.standard.array(forKey: storageKey) as? [String] {
            musicFiles = savedPaths.map { URL(fileURLWithPath: $0) }
        }
    }
}
