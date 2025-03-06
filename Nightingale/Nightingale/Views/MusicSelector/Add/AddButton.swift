import SwiftUI

struct AddButton: View {
    @State private var showAddNewPlaylist = false
    
    var body: some View {
        Button(action: { showAddNewPlaylist = true }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
        }
        .sheet(isPresented: $showAddNewPlaylist) {
            AddNewPlaylistSheet(isPresented: $showAddNewPlaylist)
        }
    }
}
