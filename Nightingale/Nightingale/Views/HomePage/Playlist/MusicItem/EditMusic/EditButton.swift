import SwiftUI

import SwiftUI

struct EditButton: View {
    @State private var showEditSheet = false
    @Binding var song: Song
    @ObservedObject private var musicLibrary = MusicLibrary.shared

    var body: some View {
        Button(action: {
            showEditSheet = true
        }) {
            Image(systemName: "ellipsis")
                .font(.title3)
                .foregroundColor(.gray)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEditSheet) {
            EditMusic(song: $song)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }
}



