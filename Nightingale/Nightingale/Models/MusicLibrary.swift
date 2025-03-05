import Foundation

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary()
    
    private let musicStorage = MusicStorage.shared
    private let musicConfig = MusicConfig.shared

    
    func addMusicFile(_ url: URL) {
        let storedURL = musicStorage.copyFileToStorage(url)
        let newMusicFile = MusicFile(from: url, url: storedURL)
        musicConfig.addMusicFileToConfig(newMusicFile)
        print("✅ Added music file: \(newMusicFile.name)")
        NotificationCenter.default.post(name: NSNotification.Name("MusicLibraryChanged"), object: nil)
    }

    
    func removeMusicFile(_ musicFile: MusicFile) {
        musicStorage.deleteFileFromStorage(musicFile.url)
        musicConfig.removeMusicFileFromConfig(musicFile)
        print("✅ Removed music file: \(musicFile.name)")
        NotificationCenter.default.post(name: NSNotification.Name("MusicLibraryChanged"), object: nil)
    }

    /*
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
    */
    
    
    func removeAllMusic() {
        musicStorage.deleteAllFilesFromStorage()
        musicConfig.removeAllMusicFilesFromConfig()
        print("✅ Removed all music from library")
        NotificationCenter.default.post(name: NSNotification.Name("MusicLibraryChanged"), object: nil)
    }
    
    func editMusicFile(_ editedMusicFile: MusicFile) {
        musicConfig.editMusicFile(editedMusicFile)
        print("Edited music file: \(editedMusicFile.name)")
        NotificationCenter.default.post(name: NSNotification.Name("MusicLibraryChanged"), object: nil)
    }
    
    func getMusicFiles() -> [MusicFile] {
        return musicConfig.getMusicFiles()
    }
}
