import Foundation

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary()
    
    private let musicStorage = MusicStorage.shared
    private let musicConfig = MusicConfig.shared
    
    init () {
        
        let result = validateConsistency()
        if !result {
            print("Validation failed")
        } else {
            print("Validation succeeded")
        }
    }
    
    func addMusicFile(_ url: URL) {
        let storedURL = musicStorage.copyFileToStorage(url)
        let newMusicFile = MusicFile(from: url, url: storedURL)
        musicConfig.addMusicFileToConfig(newMusicFile)
        print("✅ Added music file: \(newMusicFile.fileName)")
    }

    
    func removeMusicFile(_ musicFile: MusicFile) {
        musicStorage.deleteFileFromStorage(musicFile.url)
        musicConfig.removeMusicFileFromConfig(musicFile)
        print("✅ Removed music file: \(musicFile.fileName)")
    }    
    
    func removeAllMusic() {
        musicStorage.deleteAllFilesFromStorage()
        musicConfig.removeAllMusicFilesFromConfig()
        print("✅ Removed all music from library")
    }
    
    func editMusicFile(_ editedMusicFile: MusicFile) {
        musicConfig.editMusicFile(editedMusicFile)
        print("Edited music file: \(editedMusicFile.fileName)")
    }
    
    func getMusicFiles() -> [MusicFile] {
        return musicConfig.getMusicFiles()
    }
    
    private func findFilesMissingInConfig(_ storedFileNames: [String], _ musicFiles: [MusicFile]) -> [String] {
        return storedFileNames.filter { storedFile in
            !musicFiles.contains(where: { $0.fileName == storedFile })
        }
    }
    
    private func findFilesMissingInStorage(_ storedFileNames: [String], _ musicFiles: [MusicFile]) -> [MusicFile] {
        return musicFiles.filter { musicFile in
            !storedFileNames.contains(musicFile.fileName)
        }
    }
    
    private func restoreMissingFiles(_ missingFiles: [MusicFile]) {
        missingFiles.forEach { missingFile in
            addMusicFile(missingFile.from)
        }
    }
    
    func validateConsistency() -> Bool {
        let storedFileNames = musicStorage.getStoredFileNames()
        let musicFiles = musicConfig.getMusicFiles()

        let missingInConfig = findFilesMissingInConfig(storedFileNames, musicFiles)
        if !missingInConfig.isEmpty {
            print("Found \(missingInConfig.count) files in storage but not in config")
            missingInConfig.forEach { print($0) }
            return false
        }

        var missingInStorage = findFilesMissingInStorage(storedFileNames, musicFiles)
        if !missingInStorage.isEmpty {
            print("Found \(missingInStorage.count) files in config but not in storage. Attempting to restore them.")
            restoreMissingFiles(missingInStorage)
        }

        missingInStorage = findFilesMissingInStorage(storedFileNames, musicFiles)
        if !missingInStorage.isEmpty {
            print("Still found \(missingInStorage.count) files in config but not in storage after trying to add them.")
            return false
        }

        return true
    }
    
    
    
    
}
