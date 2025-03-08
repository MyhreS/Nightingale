import SwiftUI

struct RemoveSheet: View {
    @Binding var successfullyRemoved: Bool
    @State var showRemoveMusic: Bool = false
    @State var showRemovePlaylists: Bool = false
    
    var body: some View {
        ZStack {
            List {
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
                }
            }
            .listStyle(.insetGrouped)
        }
        .sheet(isPresented: $showRemoveMusic) {
            RemoveMusicSheet(successfullyRemoved: $successfullyRemoved)
        }
        .sheet(isPresented: $showRemovePlaylists) {
            RemovePlaylistSheet(successfullyRemoved: $successfullyRemoved)
        }
    }
}
