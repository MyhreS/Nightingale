import Foundation

class MusicConfig {
    static let shared = MusicConfig()
    @Published private(set) var musicFiles: [MusicFile] = []
    
    private let storageConfigKey = "SavedMusicFiles"
    
    private init() {
        loadMusicFilesFromConfig()
    }
    
    private func loadMusicFilesFromConfig() {
        guard let data = UserDefaults.standard.data(forKey: storageConfigKey) else { return }
        
    }
    
    private func updateConfig() {
        do {
            let data = try JSONEncoder().encode(musicFiles)
            UserDefaults.standard.set(data, forKey: storageConfigKey)
        } catch {
            fatalError("❌ CRITICAL ERROR: Failed to update music config: \(error.localizedDescription)")
        }
    }
    
    func addMusicFileToConfig(_ musicFile: MusicFile) {
        if(musicFiles.contains(where: {
            $0.name == musicFile.name
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
    
    /*
    func resetPlayedStatus() {
        musicFiles = musicFiles.map { musicFile in
            var updatedMusicFile = musicFile
            updatedMusicFile.played = false
            return updatedMusicFile
        }
        updateConfig()
    }
     */
    
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

