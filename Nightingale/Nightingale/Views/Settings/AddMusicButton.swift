import SwiftUI
import UniformTypeIdentifiers

struct AddMusicButton: View {
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @State private var showFilePicker = false
    @State private var isSuccess = false
    
    var body: some View {
        Button(action: {
            showFilePicker = true
        }) {
            HStack {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "plus.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSuccess ? Color.green.darker() : .blue)

                Text(isSuccess ? "Added!" : "Add")
                    .font(.body)
                    .foregroundColor(isSuccess ? Color.green.darker() : .blue)
            }
            .frame(maxWidth: .infinity) // Make both buttons equal width
            .padding()
            .background(isSuccess ? Color.green.opacity(0.3) : Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.audio],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        DispatchQueue.main.async { // Ensure UI updates happen on the main thread
            switch result {
            case .success(let urls):
                guard let fileURL = urls.first else { return }
                musicLibrary.addMusicFile(fileURL)

                isSuccess = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    isSuccess = false
                }

            case .failure(let error):
                print("File selection error: \(error.localizedDescription)")
            }
            showFilePicker = false // Explicitly dismiss file picker
        }
    }
}
