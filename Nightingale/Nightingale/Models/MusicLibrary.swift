import Foundation

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary() // Singleton instance

    @Published private(set) var musicFiles: [MusicFile] = []
    private let storageKey = "SavedMusicFiles"
    private let storage = MusicStorage.shared

    private init() {
        loadMusicFiles()
        validateConsistency() // ✅ Check consistency on startup
    }

    /// ✅ Adds a music file
    func addMusicFile(_ url: URL) -> Bool {
        // 1. Copy to storage
        guard let storedURL = storage.copyFileToStorage(url) else {
            fatalError("❌ CRITICAL ERROR: Failed to add file to storage: \(url.lastPathComponent)")
        }

        // 2. Create MusicFile
        let newMusicFile = MusicFile(url: storedURL)

        // 3. Check if it already exists in the list
        if musicFiles.contains(where: { $0.url == newMusicFile.url }) {
            fatalError("⚠️ File already exists in music library: \(storedURL.lastPathComponent)")
        }

        // 4. Add to the list
        musicFiles.append(newMusicFile)
        saveMusicFiles()
        print("✅ Successfully added music file: \(newMusicFile.name)")

        // 5. Validate consistency
        validateConsistency()

        return true
    }

    /// ✅ Removes a music file
    func removeMusicFile(_ musicFile: MusicFile) -> Bool {
        // 1. Delete from storage
        guard let deletedURL = storage.deleteFileFromStorage(musicFile.url) else {
            fatalError("❌ CRITICAL ERROR: Failed to delete file from storage: \(musicFile.name)")
        }

        // 2. Find and remove from list
        guard let index = musicFiles.firstIndex(where: { $0.url == deletedURL }) else {
            fatalError("❌ CRITICAL ERROR: File not found in music library (but deleted from storage): \(deletedURL.lastPathComponent)")
        }

        musicFiles.remove(at: index)
        saveMusicFiles()
        print("✅ Successfully removed music file: \(deletedURL.lastPathComponent)")

        // 3. Validate consistency
        validateConsistency()

        return true
    }

    /// ✅ Validates consistency between storage and the music library
    private func validateConsistency() {
        let storedFiles = storage.getStoredFiles()
        let configFiles = musicFiles.map { $0.url.lastPathComponent }

        print("🔍 Validating consistency between storage and config...")

        // Files in storage but not in config - add them back
        let missingInConfig = storedFiles.filter { !configFiles.contains($0) }
        if !missingInConfig.isEmpty {
            print("⚠️ Found files in storage missing from config, adding them back: \(missingInConfig)")
            for fileName in missingInConfig {
                let url = storage.getStorageURL(for: fileName)
                _ = addMusicFile(url)
            }
        }

        // Files in config but not in storage - remove them
        let missingInStorage = configFiles.filter { !storedFiles.contains($0) }
        if !missingInStorage.isEmpty {
            print("⚠️ Found files in config missing from storage, removing them")
            musicFiles.removeAll { missingInStorage.contains($0.url.lastPathComponent) }
            saveMusicFiles()
        }

        print("✅ Consistency check complete. All good")
    }

    /// ✅ Saves the music files persistently
    private func saveMusicFiles() {
        do {
            let data = try JSONEncoder().encode(musicFiles)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            fatalError("❌ CRITICAL ERROR: Failed to save music files: \(error.localizedDescription)")
        }
    }

    /// ✅ Loads stored music files
    private func loadMusicFiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            musicFiles = try JSONDecoder().decode([MusicFile].self, from: data)
            print("✅ Successfully loaded music files")
        } catch {
            print("❌ Failed to load music files, clearing invalid data: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: storageKey)
            musicFiles = []
        }
    }

    /// Clears the music library configuration and all files from storage
    func clearConfiguration() {
        print("🧹 Clearing music library configuration and storage...")
        
        // Clear all files from storage first
        let storedFiles = storage.getStoredFiles()
        for fileName in storedFiles {
            let fileURL = storage.getStorageURL(for: fileName)
            _ = storage.deleteFileFromStorage(fileURL)
        }
        
        // Clear configuration from UserDefaults
        UserDefaults.standard.removeObject(forKey: storageKey)
        musicFiles.removeAll()
        
        print("✅ Music library configuration and storage cleared")
    }
    
    /// Updates a song's settings
    func updateSong(_ updatedSong: MusicFile) {
        if let index = musicFiles.firstIndex(where: { $0.id == updatedSong.id }) {
            musicFiles[index] = updatedSong
            saveMusicFiles()
            print("✅ Updated song settings: \(updatedSong.name)")
        }
    }
}
