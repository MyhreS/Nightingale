import Foundation

class MusicStorage {
    static let shared = MusicStorage() // Singleton instance

    private let fileManager = FileManager.default
    private let documentsDirectory: URL

    private init() {
        documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    /// ✅ Gets the full URL for a file in storage
    func getStorageURL(for fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent(fileName)
    }

    /// ✅ Retrieves all file names from storage
    func getStoredFileNames() -> [String] {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return fileURLs.map { $0.deletingPathExtension().lastPathComponent } // Remove extension
        } catch {
            print("❌ Failed to retrieve stored file names: \(error.localizedDescription)")
            return []
        }
    }

    /// ✅ Copies a file into the app’s Documents directory (if it doesn’t already exist)
    func copyFileToStorage(_ originalURL: URL) -> URL {
        let destinationURL = getStorageURL(for: originalURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            return destinationURL
        }

        let didStartAccessing = originalURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { originalURL.stopAccessingSecurityScopedResource() } }

        do {
            try fileManager.copyItem(at: originalURL, to: destinationURL)
            return destinationURL
        } catch {
            fatalError("❌ Failed to copy file: \(error.localizedDescription)")
        }
    }

    /// ✅ Deletes a file from storage
    func deleteFileFromStorage(_ fileURL: URL) {
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
            } catch {
                fatalError("❌ Failed to delete file: \(error.localizedDescription)")
            }
        } else {
            fatalError("⚠️ File not found in storage: \(fileURL.lastPathComponent)")
        }
    }
    
    func deleteAllFilesFromStorage() {
        do {
            let fileNames = try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
            
            for fileName in fileNames {
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            fatalError("❌ Failed to delete all files: \(error.localizedDescription)")
        }
    }
}
