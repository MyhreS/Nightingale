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
        // ✅ Ensure file exists in storage
        let storedURL: URL
        let storedFiles = getStoredFiles()

        if storedFiles.contains(url.lastPathComponent) {
            print("⚠️ File already exists in storage: \(url.lastPathComponent)")
            storedURL = getStorageURL(for: url.lastPathComponent) // Get the URL from storage
        } else {
            // ✅ Copy to storage if it doesn't exist
            guard let copiedURL = copyFileToAppStorage(url) else {
                print("❌ Failed to copy file to storage: \(url.lastPathComponent)")
                return false
            }
            storedURL = copiedURL
            print("✅ File copied to storage: \(storedURL.lastPathComponent)")
        }

        // ✅ Sync Music Files list with storage
        syncMusicFilesWithStorage()

        // ✅ Check if the file is already in the `musicFiles` list
        if musicFiles.contains(where: { $0.url == storedURL }) {
            print("⚠️ File already exists in the music library: \(storedURL.lastPathComponent)")
            return false
        }

        // ✅ Add the new file to the `musicFiles` list
        let newMusicFile = MusicFile(url: storedURL)
        musicFiles.append(newMusicFile)
        saveMusicFiles()
        print("✅ Successfully added music file: \(newMusicFile.name)")

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

    /// Retrieves all file names from storage
    private func getStoredFiles() -> [String] {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            return fileNames
        } catch {
            print("❌ Failed to retrieve stored files: \(error.localizedDescription)")
            return []
        }
    }
    
    /// Gets the full URL for a file in storage
    private func getStorageURL(for fileName: String) -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
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
        debugPrintStorageContents()
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
