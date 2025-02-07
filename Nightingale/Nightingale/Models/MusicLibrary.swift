import Foundation
import UniformTypeIdentifiers

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary() // Singleton instance

    @Published private(set) var musicFiles: [MusicFile] = []

    private let storageKey = "SavedMusicFiles"

    private init() {
        self.musicFiles = [
            MusicFile(url: URL(fileURLWithPath: "/mock/path/ACDC - Mock Highway to Hell.mp3")),
            MusicFile(url: URL(fileURLWithPath: "/mock/path/Queen - Mock Bohemian Rhapsody.mp3")),
            MusicFile(url: URL(fileURLWithPath: "/mock/path/Nirvana - Mock Smells Like Teen Spirit.mp3"))
        ]
            
        loadMusicFiles()
    }

    /// ✅ Now accepts a **URL** instead of a **String**
    func addMusicFile(_ url: URL) -> Bool {
        let newMusicFile = MusicFile(url: url)
        guard !musicFiles.contains(where: { $0.url == newMusicFile.url }) else {
            print("File already exists: \(newMusicFile.name)")
            return false // ✅ Return false if duplicate
        }
        musicFiles.append(newMusicFile)
        saveMusicFiles()
        return true // ✅ Return true if successfully added
    }

    /// Removes a music file and updates storage
    func removeMusicFile(_ musicFile: MusicFile) {
        musicFiles.removeAll { $0.id == musicFile.id }
        saveMusicFiles()
    }

    /// Clears all stored music files
    func clearMusicLibrary() {
        musicFiles.removeAll()
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    /// Saves the music files persistently
    private func saveMusicFiles() {
        do {
            let data = try JSONEncoder().encode(musicFiles)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("Failed to save music files: \(error.localizedDescription)")
        }
    }

    /// Loads stored music files
    private func loadMusicFiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            musicFiles = try JSONDecoder().decode([MusicFile].self, from: data)
        } catch {
            print("Failed to load music files: \(error.localizedDescription)")
        }
    }
}
