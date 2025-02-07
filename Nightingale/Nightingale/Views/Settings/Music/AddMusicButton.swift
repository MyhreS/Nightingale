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
            allowsMultipleSelection: false // ✅ Allow only one file at a time
        ) { result in
            handleFileSelection(result)
        }
    }

    /// ✅ Handles the file selection and copies it to app storage
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let urls):
                if let fileURL = urls.first {
                    let storedURL = copyFileToAppStorage(fileURL) // ✅ Copy file to app storage
                    let success = musicLibrary.addMusicFile(storedURL)
                    if success {
                        print("✅ Successfully added music file: \(storedURL.lastPathComponent)")
                    } else {
                        print("⚠️ File already exists in library: \(storedURL.lastPathComponent)")
                    }
                } else {
                    print("❌ No file selected")
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
            print("✅ File already exists in app storage: \(destinationURL.path)")
            return destinationURL
        }

        // ✅ Request secure access
        let didStartAccessing = originalURL.startAccessingSecurityScopedResource()
        defer { if didStartAccessing { originalURL.stopAccessingSecurityScopedResource() } }

        do {
            // ✅ Copy the file securely
            try fileManager.copyItem(at: originalURL, to: destinationURL)
            print("✅ File copied to app storage: \(destinationURL.path)")
        } catch {
            print("❌ Failed to copy file: \(error.localizedDescription)")
        }

        return destinationURL
    }
}
