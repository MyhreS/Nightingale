import SwiftUI
import UniformTypeIdentifiers

struct AddSheet: View {
    @State private var showCreatePlaylist = false
    @StateObject private var fileImporterHelper = FileImporterHelper() // ✅ Use new helper

    var body: some View {
        ZStack {
            List {
                Section {
                    Button(action: { fileImporterHelper.showFilePicker = true }) { // ✅ Trigger file picker
                        HStack {
                            Image(systemName: "music.note.list")
                                .frame(width: 25)
                            Text("Add song")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .fileImporter( // ✅ Attach fileImporter here
                        isPresented: $fileImporterHelper.showFilePicker,
                        allowedContentTypes: [UTType.audio],
                        allowsMultipleSelection: true,
                        onCompletion: fileImporterHelper.handleFileSelection
                    )

                    Button(action: { showCreatePlaylist = true }) {
                        HStack {
                            Image(systemName: "plus.rectangle.on.folder")
                                .frame(width: 25)
                            Text("Create playlist")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                }
            }
            .listStyle(.insetGrouped)
        }
    }
}
