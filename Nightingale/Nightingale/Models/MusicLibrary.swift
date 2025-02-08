import Foundation

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary() // Singleton instance

    @Published private(set) var musicFiles: [MusicFile] = []
    private let storageKey = "SavedMusicFiles"
    private let storage = MusicStorage.shared

    private init() {
        loadMusicFiles()
        syncMusicFilesWithStorage() // ✅ Ensure storage & list match at startup
    }

    /// ✅ Adds a music file if it doesn't already exist
    func addMusicFile(_ url: URL) -> Bool {
        let initialCount = musicFiles.count // Store initial size

        // ✅ Copy to storage if necessary
        let storedURL = storage.copyFileToStorage(url) ?? storage.getStorageURL(for: url.lastPathComponent)

        // ✅ Sync Music Files list with storage
        syncMusicFilesWithStorage()

        // ✅ Check if file already exists in music list
        if musicFiles.contains(where: { $0.url == storedURL }) {
            print("⚠️ File already exists in music library: \(storedURL.lastPathComponent)")
        } else {
            // ✅ Add the new file to the `musicFiles` list
            let newMusicFile = MusicFile(url: storedURL)
            musicFiles.append(newMusicFile)
            saveMusicFiles()
            print("✅ Successfully added music file: \(newMusicFile.name)")
        }

        return musicFiles.count > initialCount // ✅ Returns true if the list grew
    }

    /// ✅ Ensures the `musicFiles` list only contains files that actually exist in storage
    private func syncMusicFilesWithStorage() {
        let storedFiles = storage.getStoredFiles()
        print("🔄 Syncing storage with MusicLibrary...")

        // ✅ Remove missing files from `musicFiles`
        musicFiles = musicFiles.filter { storedFiles.contains($0.url.lastPathComponent) }

        // ✅ Add missing storage files to `musicFiles`
        for file in storedFiles {
            let fileURL = storage.getStorageURL(for: file)
            if !musicFiles.contains(where: { $0.url == fileURL }) {
                print("➕ Adding missing file from storage: \(file)")
                musicFiles.append(MusicFile(url: fileURL))
            }
        }

        saveMusicFiles()
        print("✅ MusicLibrary is now in sync with storage.")
    }

    /// ✅ Removes a music file from both the library and storage
    func removeMusicFile(_ musicFile: MusicFile) {
        print("🔍 Storage contents BEFORE removal:")
        debugPrintStorageContents()

        if storage.deleteFileFromStorage(musicFile.url) {
            musicFiles.removeAll { $0.id == musicFile.id }
            saveMusicFiles()
        }

        syncMusicFilesWithStorage()
        print("🔍 Storage contents AFTER removal:")
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

    /// ✅ Prints all files in app storage
    private func debugPrintStorageContents() {
        let storedFiles = storage.getStoredFiles()
        if storedFiles.isEmpty {
            print("📂 Storage is EMPTY")
        } else {
            for file in storedFiles {
                print("📄 \(file)")
            }
        }
    }
}
