import SwiftUI
import UniformTypeIdentifiers

struct AddMusicButton: View {
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @State private var showFilePicker = false
    @State private var isSuccess = false
    @State private var successMessage = "Add Music"

    var body: some View {
        Button(action: {
            provideHapticFeedback()
            showFilePicker = true
        }) {
            HStack {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "plus.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSuccess ? Color.green.darker() : .blue.darker())

                Text(successMessage)
                    .font(.body)
                    .foregroundColor(isSuccess ? Color.green.darker() : .blue.darker())
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

    /// ✅ Handles file selection and sends the URLs to `MusicLibrary`
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success(let urls):
                let addedCount = urls.filter { musicLibrary.addMusicFile($0) }.count

                if addedCount == 0 {
                    successMessage = "No new files"
                } else if addedCount == 1 {
                    successMessage = "Added 1 file!"
                } else {
                    successMessage = "Added \(addedCount) files!"
                }

                isSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isSuccess = false
                    successMessage = "Add Music" // Reset text
                }

            case .failure(let error):
                print("❌ File selection error: \(error.localizedDescription)")
            }

            showFilePicker = false // Explicitly dismiss file picker
        }
    }
}
