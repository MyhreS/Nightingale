import Foundation

class MusicConfig {
    static let shared = MusicConfig()
    @Published private(set) var musicConfigItems: [Song] = []
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
            musicConfigItems = try JSONDecoder().decode([Song].self, from: data)
        } catch {
            print("❌ Failed to decode music files: \(error.localizedDescription)")
            print("🧐 Raw stored data: \(String(data: data, encoding: .utf8) ?? "Invalid UTF-8 Data")")
            fatalError("CRITICAL ERROR: Failed to load music config")
        }
    }
    
    private func updateConfig() {
        do {
            let data = try JSONEncoder().encode(musicConfigItems)
            UserDefaults.standard.set(data, forKey: storageConfigKey)
            UserDefaults.standard.synchronize() // ✅ Force save
        } catch {
            fatalError("❌ CRITICAL ERROR: Failed to update music config: \(error.localizedDescription)")
        }
    }
    
    func addMusicFileToConfig(_ musicFile: Song) {
        if(musicConfigItems.contains(where: {
            $0.fileName == musicFile.fileName
        })) {
            return
        }
        musicConfigItems.append(musicFile)
        updateConfig()
    }
    
    func removeMusicFileFromConfig(_ musicFile: Song) {
        guard let index = musicConfigItems.firstIndex(where: { $0.url == musicFile.url }) else {
            fatalError("❌ CRITICAL ERROR: File not found in music library (but deleted from storage): \(musicFile.url.lastPathComponent)")
        }
        musicConfigItems.remove(at: index)
        updateConfig()
    }
    
    func removeAllMusicFilesFromConfig() {
        musicConfigItems.removeAll()
        updateConfig()
    }
    
    func editMusicFile(_ editedMusicFile: Song) {
        guard let index = musicConfigItems.firstIndex(where: {$0.id == editedMusicFile.id}) else {
            fatalError("❌ CRITICAL ERROR: Music file not found when updating it: \(editedMusicFile.id)")
        }
        musicConfigItems[index] = editedMusicFile
        updateConfig()
    }
    
    func getMusicConfigItems() -> [Song] {
        return musicConfigItems
    }
}

