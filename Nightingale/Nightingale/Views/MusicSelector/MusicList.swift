import SwiftUI

struct MusicList: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared

    var body: some View {
        List(musicLibrary.musicFiles, id: \.self) { file in
            MusicItem(file: file) // Use the updated MusicItem
        }
        .listStyle(.plain) // Remove extra styling
        .scrollContentBackground(.hidden) // Ensure transparent background
        .padding(.leading, 0) // Remove extra padding on the left
    }
}
