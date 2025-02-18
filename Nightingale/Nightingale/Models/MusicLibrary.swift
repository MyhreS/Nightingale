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

        // Files in storage but not in config
        let missingInConfig = storedFiles.filter { !configFiles.contains($0) }
        if !missingInConfig.isEmpty {
            fatalError("❌ CRITICAL ERROR: Files in storage but missing in config: \(missingInConfig)")
        }

        // Files in config but not in storage
        let missingInStorage = configFiles.filter { !storedFiles.contains($0) }
        if !missingInStorage.isEmpty {
            fatalError("❌ CRITICAL ERROR: Files in config but missing in storage: \(missingInStorage)")
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
        } catch {
            fatalError("❌ CRITICAL ERROR: Failed to load music files: \(error.localizedDescription)")
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
}
