import SwiftUI
import UniformTypeIdentifiers

class FileImporterHelper: ObservableObject {
    @Published var showFilePicker = false
    @Published var isSuccess = false // ✅ Notifies AddButton
    @Published var successMessage = "Add Music"

    private let musicLibrary = MusicLibrary.shared

    func handleFileSelection(_ result: Result<[URL], Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let urls):
                urls.forEach { url in
                    self.musicLibrary.addMusicFile(url)
                }

                let addedCount = urls.count
                self.successMessage = addedCount == 0 ? "No new files" : "Added \(addedCount) file(s)!"
                self.isSuccess = true // ✅ Trigger success state

                // Reset success state after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.isSuccess = false
                    self.successMessage = "Add Music"
                }

            case .failure(let error):
                print("❌ File selection error: \(error.localizedDescription)")
            }

            self.showFilePicker = false
        }
    }
}
