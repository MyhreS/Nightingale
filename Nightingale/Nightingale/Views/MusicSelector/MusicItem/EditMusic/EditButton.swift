import SwiftUI

import SwiftUI

struct EditButton: View {
    @State private var showEditSheet = false
    var song: Song
    @ObservedObject private var musicLibrary = MusicLibrary.shared

    var body: some View {
        Button(action: {
            showEditSheet = true
        }) {
            Image(systemName: "slider.horizontal.3")
                .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showEditSheet) {
            EditMusic(song: song)
                .presentationDetents([.height(250)])
                .presentationDragIndicator(.visible)
        }
    }
}



