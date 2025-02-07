import SwiftUI
import UniformTypeIdentifiers

struct AddMusicButton: View {
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @State private var showFilePicker = false
    @State private var isSuccess = false
    @State private var successMessage = "Add" // Update success message

    var body: some View {
        Button(action: {
            showFilePicker = true
        }) {
            HStack {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "plus.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSuccess ? Color.green.darker() : .blue)

                Text(successMessage)
                    .font(.body)
                    .foregroundColor(isSuccess ? Color.green.darker() : .blue)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSuccess ? Color.green.opacity(0.3) : Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.audio],
            allowsMultipleSelection: true // ✅ Enable multiple selections
        ) { result in
            handleFileSelection(result)
        }
    }

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        DispatchQueue.main.async { // Ensure UI updates happen on the main thread
            switch result {
            case .success(let urls):
                // Convert URLs to Strings and add to the library
                let addedFiles = urls.filter { musicLibrary.addMusicFile($0.path) }
                
                if addedFiles.isEmpty {
                    successMessage = "No new files"
                } else if addedFiles.count == 1 {
                    successMessage = "Added 1 file!"
                } else {
                    successMessage = "Added \(addedFiles.count) files!"
                }

                isSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isSuccess = false
                    successMessage = "Add" // Reset text
                }

            case .failure(let error):
                print("File selection error: \(error.localizedDescription)")
            }
            showFilePicker = false // Explicitly dismiss file picker
        }
    }
}
