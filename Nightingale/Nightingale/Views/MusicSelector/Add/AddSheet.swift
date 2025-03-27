import SwiftUI
import UniformTypeIdentifiers

struct AddSheet: View {
    @State private var showCreatePlaylist = false
    @ObservedObject var fileImporterHelper: FileImporterHelper
    @Binding var successfullyAddedPlaylist: Bool
    private let musicLibrary = MusicLibrary.shared

    var body: some View {
        ZStack {
            List {
                Section {
                    Button(action: { fileImporterHelper.showFilePicker = true }) {
                        HStack {
                            Image(systemName: "music.note.list")
                                .frame(width: 25)
                            Text("Add music")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .fileImporter(
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
                    .disabled(musicLibrary.songs.isEmpty)
                }
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $showCreatePlaylist) {
            CreatePlaylistSheet(isPresented: $showCreatePlaylist, successfullyAddedPlaylist: $successfullyAddedPlaylist)
        }
    }
}
