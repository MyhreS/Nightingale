import SwiftUI
import UniformTypeIdentifiers

struct AddMusicButton: View {
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @State private var showFilePicker = false

    var body: some View {
        Button(action: {
            showFilePicker = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.blue.darker())

                Text("Add Music")
                    .font(.body)
                    .foregroundColor(.blue.darker())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.audio], // ✅ Allow only audio files
            allowsMultipleSelection: true // ✅ Now allows multiple files
        ) { result in
            handleFileSelection(result)
        }
    }

    /// ✅ Handles file selection & copies multiple files
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let urls):
                var addedCount = 0
                for fileURL in urls {
                    let storedURL = copyFileToAppStorage(fileURL) // ✅ Copy each file
                    let success = musicLibrary.addMusicFile(storedURL)
                    if success {
                        addedCount += 1
                        print("✅ Successfully added: \(storedURL.lastPathComponent)")
                    } else {
                        print("⚠️ Already exists: \(storedURL.lastPathComponent)")
                    }
                }
                if addedCount > 0 {
                    print("✅ Added \(addedCount) new files to library.")
                }

            case .failure(let error):
                print("❌ File selection error: \(error.localizedDescription)")
            }
        }
    }

    /// ✅ Securely copies a file into the app’s Documents directory
    private func copyFileToAppStorage(_ originalURL: URL) -> URL {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationURL = documentsDirectory.appendingPathComponent(originalURL.lastPathComponent)

        // ✅ Check if file already exists to avoid duplicates
        if fileManager.fileExists(atPath: destinationURL.path) {
            print("✅ File already exists: \(destinationURL.path)")
            return destinationURL
        }

        // ✅ Request secure access
        let didStartAccessing = originalURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { originalURL.stopAccessingSecurityScopedResource() } }

        do {
            try fileManager.copyItem(at: originalURL, to: destinationURL)
            print("✅ Copied file to storage: \(destinationURL.path)")
        } catch {
            print("❌ Copy failed: \(error.localizedDescription)")
        }

        return destinationURL
    }
}
