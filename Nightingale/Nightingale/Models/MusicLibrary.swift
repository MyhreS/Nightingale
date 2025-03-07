import Foundation
import Combine

class MusicLibrary: ObservableObject {
    static let shared = MusicLibrary()
    
    private let musicStorage = MusicStorage.shared
    private let musicConfig = MusicConfig.shared
    private let playlistsManager = PlaylistsManager.shared
    
    @Published var songs: [Song] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
            musicConfig.$musicConfigItems
                .sink { [weak self] newMusicItems in
                    var allSongs = newMusicItems
                    
                    // ✅ Add dummy song only in preview
                    if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                        let dummySong = Song.dummySong()
                        if !allSongs.contains(where: { $0.id == dummySong.id }) {
                            allSongs.append(dummySong)
                        }
                    }
                    
                    self?.songs = allSongs
                }
                .store(in: &cancellables)

            let result = validateConsistency()
            print(result ? "Validation succeeded" : "Validation failed")
        }
    
    func addMusicFile(_ url: URL) {
        let storedURL = musicStorage.copyFileToStorage(url)
        let newMusicFile = Song(from: url, url: storedURL)
        musicConfig.addMusicFileToConfig(newMusicFile)
        print("✅ Added music file: \(newMusicFile.fileName)")
    }

    
    func removeMusicFile(_ musicFile: Song) {
        musicStorage.deleteFileFromStorage(musicFile.url)
        musicConfig.removeMusicFileFromConfig(musicFile)
        print("✅ Removed music file: \(musicFile.fileName)")
    }    
    
    func removeAllMusic() {
        musicStorage.deleteAllFilesFromStorage()
        musicConfig.removeAllMusicFilesFromConfig()
        print("✅ Removed all music from library")
    }
    
    func editMusicFile(_ editedMusicFile: Song) {
        musicConfig.editMusicFile(editedMusicFile)
        print("Edited music file: \(editedMusicFile.fileName)")
    }
    
    private func findFilesMissingInConfig(_ storedFileNames: [String], _ musicFiles: [Song]) -> [String] {
        return storedFileNames.filter { storedFile in
            !musicFiles.contains(where: { $0.fileName == storedFile })
        }
    }
    
    private func findFilesMissingInStorage(_ storedFileNames: [String], _ musicFiles: [Song]) -> [Song] {
        return musicFiles.filter { musicFile in
            !storedFileNames.contains(musicFile.fileName)
        }
    }
    
    private func restoreMissingFiles(_ missingFiles: [Song]) {
        missingFiles.forEach { missingFile in
            addMusicFile(missingFile.from)
        }
    }
    
    func validateConsistency() -> Bool {
        let storedFileNames = musicStorage.getStoredFileNames()
        let musicFiles = musicConfig.getMusicConfigItems()

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
