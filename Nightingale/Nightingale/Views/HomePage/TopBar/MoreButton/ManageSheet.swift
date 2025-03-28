import SwiftUI
import UniformTypeIdentifiers

struct ManageSheet: View {
    @ObservedObject var fileImporterHelper = FileImporterHelper()
    @ObservedObject private var musicLibrary = MusicLibrary.shared

    @State private var showFilePicker = false
    @State private var showCreatePlaylist = false
    @State private var showRemoveMusic = false
    @State private var showRemovePlaylists = false

    @State private var successfullyAddedPlaylist = false
    @State private var successfullyRemoved = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button(action: { showFilePicker = true }) {
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
                } header: {
                    Text("Add")
                }

                Section {
                    Button(action: { showRemoveMusic = true }) {
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(.red)
                                .frame(width: 25)
                            Text("Remove music")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())

                    Button(action: { showRemovePlaylists = true }) {
                        HStack {
                            Image(systemName: "folder.badge.minus")
                                .foregroundColor(.red)
                                .frame(width: 25)
                            Text("Remove playlist")
                                .foregroundColor(.red)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                } header: {
                    Text("Remove")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Manage")
            .navigationBarTitleDisplayMode(.inline)
        }
        // Sub-sheets:
        .sheet(isPresented: $showCreatePlaylist) {
            CreatePlaylistSheet(
                isPresented: $showCreatePlaylist,
                successfullyAddedPlaylist: $successfullyAddedPlaylist
            )
        }
        .sheet(isPresented: $showRemoveMusic) {
            RemoveMusicSheet(successfullyRemoved: $successfullyRemoved)
        }
        .sheet(isPresented: $showRemovePlaylists) {
            RemovePlaylistSheet(successfullyRemoved: $successfullyRemoved)
        }
        // File importer:
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [UTType.audio],
            allowsMultipleSelection: true,
            onCompletion: fileImporterHelper.handleFileSelection
        )
    }
}
