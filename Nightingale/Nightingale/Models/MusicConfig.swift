import Foundation

class MusicConfig {
    static let shared = MusicConfig()
    @Published private(set) var musicFiles: [MusicFile] = []
    
    private let storageConfigKey = "SavedMusicFiles"
    
    private init() {
        loadMusicFilesFromConfig()
    }
    
    private func loadMusicFilesFromConfig() {
        guard let data = UserDefaults.standard.data(forKey: storageConfigKey) else {
            print("⚠️ No saved music files found in UserDefaults.")
            return
        }

        do {
            musicFiles = try JSONDecoder().decode([MusicFile].self, from: data)
        } catch {
            print("❌ Failed to decode music files: \(error.localizedDescription)")
            print("🧐 Raw stored data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8 Data")")
            fatalError("CRITICAL ERROR: Failed to load music config")
        }
    }
    
    private func updateConfig() {
        do {
            let data = try JSONEncoder().encode(musicFiles)
            UserDefaults.standard.set(data, forKey: storageConfigKey)
            UserDefaults.standard.synchronize() // ✅ Force save
        } catch {
            fatalError("❌ CRITICAL ERROR: Failed to update music config: \(error.localizedDescription)")
        }
    }
    
    func addMusicFileToConfig(_ musicFile: MusicFile) {
        if(musicFiles.contains(where: {
            $0.fileName == musicFile.fileName
        })) {
            return
        }
        musicFiles.append(musicFile)
        updateConfig()
    }
    
    func removeMusicFileFromConfig(_ musicFile: MusicFile) {
        guard let index = musicFiles.firstIndex(where: { $0.url == musicFile.url }) else {
            fatalError("❌ CRITICAL ERROR: File not found in music library (but deleted from storage): \(musicFile.url.lastPathComponent)")
        }
        musicFiles.remove(at: index)
        updateConfig()
    }
    
    func removeAllMusicFilesFromConfig() {
        musicFiles.removeAll()
        updateConfig()
    }
    
    func editMusicFile(_ editedMusicFile: MusicFile) {
        guard let index = musicFiles.firstIndex(where: {$0.id == editedMusicFile.id}) else {
            fatalError("❌ CRITICAL ERROR: Music file not found when updating it: \(editedMusicFile.id)")
        }
        musicFiles[index] = editedMusicFile
        updateConfig()
    }
    
    func getMusicFiles() -> [MusicFile] {
        return musicFiles
    }
    
    
    
}

