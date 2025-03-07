import SwiftUI
import UniformTypeIdentifiers

enum ImportStatus {
    case idle
    case success
    case failure
}

class FileImporterHelper: ObservableObject {
    @Published var showFilePicker = false
    @Published var triedToAddMusic = false
    @Published var status: ImportStatus = .idle

    private let musicLibrary = MusicLibrary.shared

    func handleFileSelection(_ result: Result<[URL], Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let urls):
                urls.forEach { url in
                    self.musicLibrary.addMusicFile(url)
                }

                let addedCount = urls.count
                self.status = .success

                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.status = .idle
                }

            case .failure(let error):
                print("❌ File selection error: \(error.localizedDescription)")
                self.status = .failure
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.status = .idle
                }
            }

            self.showFilePicker = false
        }
    }
}
