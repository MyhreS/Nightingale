import SwiftUI

struct RemovePlaylistSheet: View {
    @Binding var successfullyRemoved: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedPlaylists: Set<String> = []

    var body: some View {
        
        NavigationView {
            /*List(playlistManager.playlists, id: \.self, selection: $selectedPlaylists) { playlist in */
                HStack {
                    Text("some playlist")
                    Spacer()
                    if selectedPlaylists.contains("some playlist") {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedPlaylists.contains("some playlist") {
                        selectedPlaylists.remove("some playlist")
                    } else {
                        selectedPlaylists.insert("some playlist")
                    }
                }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Remove Playlist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Remove") {
                        removeSelectedPlaylists()
                    }
                    .disabled(selectedPlaylists.isEmpty)
                }
            }
        }
    }

    private func removeSelectedPlaylists() {
        /*
        for playlist in selectedPlaylists {
            playlistManager.removePlaylist(playlist)
        }
        selectedPlaylists.removeAll()
        successfullyRemoved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            successfullyRemoved = false
        }
        presentationMode.wrappedValue.dismiss()
         */
    }
}
