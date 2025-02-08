import Foundation

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary() // Singleton instance

    @Published private(set) var musicFiles: [MusicFile] = []

    private let storageKey = "SavedMusicFiles"

    private init() {
        syncMusicFilesWithStorage() // ✅ Ensure storage & list match at startup
        loadMusicFiles()
    }

    /// ✅ Add a new music file only if it doesn’t already exist in storage or list
    func addMusicFile(_ url: URL) -> Bool {
        let storedFiles = getStoredFiles()
        let newMusicFile = MusicFile(url: url)

        // ✅ Check if file already exists in storage
        if storedFiles.contains(url.lastPathComponent) {
            print("⚠️ File already exists in storage: \(newMusicFile.name)")
            return false
        }

        // ✅ Check if file already exists in list
        if musicFiles.contains(where: { $0.url == newMusicFile.url }) {
            print("⚠️ File already exists in music library: \(newMusicFile.name)")
            return false
        }

        // ✅ Add file to storage
        let storedURL = copyFileToAppStorage(url)
        if storedURL != nil {
            musicFiles.append(MusicFile(url: storedURL!))
            saveMusicFiles()
            print("✅ Successfully added music file: \(newMusicFile.name)")
        } else {
            print("❌ Failed to add file: \(newMusicFile.name)")
            return false
        }

        syncMusicFilesWithStorage() // ✅ Ensure storage & list are in sync
        return true
    }

    /// ✅ Ensures the `musicFiles` list only contains files that actually exist in storage
    private func syncMusicFilesWithStorage() {
        let storedFiles = getStoredFiles()

        print("🔄 Syncing storage with MusicLibrary...")

        // ✅ Remove missing files from `musicFiles`
        musicFiles = musicFiles.filter { storedFiles.contains($0.url.lastPathComponent) }

        // ✅ Add missing storage files to `musicFiles`
        for file in storedFiles {
            let fileURL = getDocumentsDirectory().appendingPathComponent(file)
            if !musicFiles.contains(where: { $0.url == fileURL }) {
                print("➕ Adding missing file from storage: \(file)")
                musicFiles.append(MusicFile(url: fileURL))
            }
        }

        saveMusicFiles()
        print("✅ MusicLibrary is now in sync with storage.")
    }

    /// ✅ Returns an array of file names currently in app storage
    private func getStoredFiles() -> [String] {
        let fileManager = FileManager.default
        let documentsDirectory = getDocumentsDirectory()

        do {
            return try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
        } catch {
            print("❌ Error retrieving storage files: \(error.localizedDescription)")
            return []
        }
    }
    
    /*
    /// ✅ Prints all files in app storage
    private func debugPrintStorageContents() {
        let storedFiles = getStoredFiles()
        if storedFiles.isEmpty {
            print("📂 Storage is EMPTY")
        } else {
            for file in storedFiles {
                print("📄 \(file)")
            }
        }
    }
    */

    /// ✅ Securely copies a file into the app’s Documents directory
    private func copyFileToAppStorage(_ originalURL: URL) -> URL? {
        let fileManager = FileManager.default
        let destinationURL = getDocumentsDirectory().appendingPathComponent(originalURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            print("✅ File already exists in app storage: \(destinationURL.lastPathComponent)")
            return destinationURL
        }

        // ✅ Request secure access
        let didStartAccessing = originalURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { originalURL.stopAccessingSecurityScopedResource() } }

        do {
            try fileManager.copyItem(at: originalURL, to: destinationURL)
            print("✅ File copied to app storage: \(destinationURL.path)")
            return destinationURL
        } catch {
            print("❌ Failed to copy file: \(error.localizedDescription)")
            return nil
        }
    }

    /// ✅ Returns the app's Documents directory
    private func getDocumentsDirectory() -> URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// ✅ Removes a music file ONLY if it was deleted from storage
    func removeMusicFile(_ musicFile: MusicFile) {
        let fileManager = FileManager.default

        var fileDeleted = false
        if fileManager.fileExists(atPath: musicFile.url.path) {
            do {
                try fileManager.removeItem(at: musicFile.url)
                fileDeleted = true
                print("🗑️ Deleted file: \(musicFile.name)")
            } catch {
                print("❌ Failed to delete file: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ File not found in storage: \(musicFile.name)")
        }

        if fileDeleted {
            musicFiles.removeAll { $0.id == musicFile.id }
            saveMusicFiles()
        }

        syncMusicFilesWithStorage()
    }

    /// ✅ Saves the music files persistently
    private func saveMusicFiles() {
        do {
            let data = try JSONEncoder().encode(musicFiles)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save music files: \(error.localizedDescription)")
        }
    }

    /// ✅ Loads stored music files
    private func loadMusicFiles() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        do {
            musicFiles = try JSONDecoder().decode([MusicFile].self, from: data)
        } catch {
            print("❌ Failed to load music files: \(error.localizedDescription)")
        }
    }
}
