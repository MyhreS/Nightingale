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
    func getStoredFiles() -> [String] {
        do {
            return try fileManager.contentsOfDirectory(atPath: documentsDirectory.path)
        } catch {
            print("❌ Failed to retrieve stored files: \(error.localizedDescription)")
            return []
        }
    }

    /// ✅ Copies a file into the app’s Documents directory (if it doesn’t already exist)
    func copyFileToStorage(_ originalURL: URL) -> URL? {
        let destinationURL = getStorageURL(for: originalURL.lastPathComponent)

        if fileManager.fileExists(atPath: destinationURL.path) {
            print("✅ File already exists in storage: \(destinationURL.lastPathComponent)")
            return destinationURL
        }

        let didStartAccessing = originalURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { originalURL.stopAccessingSecurityScopedResource() } }

        do {
            try fileManager.copyItem(at: originalURL, to: destinationURL)
            print("✅ File copied to storage: \(destinationURL.path)")
            return destinationURL
        } catch {
            print("❌ Failed to copy file: \(error.localizedDescription)")
            return nil
        }
    }

    /// ✅ Deletes a file from storage
    func deleteFileFromStorage(_ fileURL: URL) -> Bool {
        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                print("🗑️ Successfully deleted file: \(fileURL.lastPathComponent)")
                return true
            } catch {
                print("❌ Failed to delete file: \(error.localizedDescription)")
            }
        } else {
            print("⚠️ File not found in storage: \(fileURL.lastPathComponent)")
        }
        return false
    }
}
