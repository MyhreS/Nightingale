import SwiftUI

struct AddNewPlaylistSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject private var playlistManager = PlaylistManager.shared
    
    @State private var newPlaylistName: String = ""
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter playlist name", text: $newPlaylistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        createPlaylist()
                    }
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                
                if !newPlaylistName.isEmpty && playlistManager.getPlaylists().contains(newPlaylistName) {
                    Text("This playlist already exists")
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button(action: createPlaylist) {
                    Text("Create Playlist")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(newPlaylistName.isEmpty || playlistManager.getPlaylists().contains(newPlaylistName))
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("New Playlist")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .interactiveDismissDisabled()
    }
    
    private func createPlaylist() {
        let trimmedName = newPlaylistName.trimmingCharacters(in: .whitespacesAndNewlines)
        if playlistManager.createPlaylist(trimmedName) {
            isPresented = false
        }
    }
}
