import SwiftUI

struct CreatePlaylistSheet: View {
    @Binding var isPresented: Bool
    @State private var playlistName: String = ""
    @Binding var successfullyAddedPlaylist: Bool

    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter playlist name", text: $playlistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Button(action: {
                    if !playlistName.isEmpty {
                        // playlistsManager.addPlaylist(playlistName)
                        successfullyAddedPlaylist = true
                        isPresented = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            successfullyAddedPlaylist = false
                        }
                    }
                }) {
                    Text("Create")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("New Playlist")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
