import Foundation

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary() // Singleton instance

    @Published private(set) var musicFiles: [MusicFile] = []

    private let storageKey = "SavedMusicFiles"

    private init() {
        loadMusicFiles()
    }

    /// ✅ Add a new music file if it doesn’t already exist
    func addMusicFile(_ url: URL) -> Bool {
        let newMusicFile = MusicFile(url: url)
        guard !musicFiles.contains(where: { $0.url == newMusicFile.url }) else {
            print("⚠️ File already exists: \(newMusicFile.name)")
            return false
        }
        musicFiles.append(newMusicFile)
        saveMusicFiles()
        return true
    }

    /// ✅ Remove a music file & delete it from storage
    func removeMusicFile(_ musicFile: MusicFile) {
        // ✅ Delete file from storage
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: musicFile.url.path) {
            do {
                try fileManager.removeItem(at: musicFile.url)
                print("🗑️ Deleted file: \(musicFile.name)")
            } catch {
                print("❌ Failed to delete file: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ File not found in storage: \(musicFile.name)")
        }

        // ✅ Remove from library
        musicFiles.removeAll { $0.id == musicFile.id }
        saveMusicFiles()
    }

    /// Clears all stored music files & deletes them from storage
    func clearMusicLibrary() {
        let fileManager = FileManager.default
        for musicFile in musicFiles {
            if fileManager.fileExists(atPath: musicFile.url.path) {
                do {
                    try fileManager.removeItem(at: musicFile.url)
                    print("🗑️ Deleted file: \(musicFile.name)")
                } catch {
                    print("❌ Failed to delete file: \(error.localizedDescription)")
                }
            }
        }
        musicFiles.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Saves the music files persistently
    private func saveMusicFiles() {
        do {
            let data = try JSONEncoder().encode(musicFiles)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save music files: \(error.localizedDescription)")
        }
    }

    /// Loads stored music files
    private func loadMusicFiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            musicFiles = try JSONDecoder().decode([MusicFile].self, from: data)
        } catch {
            print("❌ Failed to load music files: \(error.localizedDescription)")
        }
    }
}
