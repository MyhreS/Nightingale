import SwiftUI

struct MusicList: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared

    var body: some View {
        List(musicLibrary.musicFiles, id: \.self) { file in
            MusicItem(musicFile: file) // Pass the MusicFile object to MusicItem
        }
        .listStyle(.plain) // Removes default styling
        .scrollContentBackground(.hidden) // Transparent background for the list
        .padding(.leading, 0) // Removes left padding from the list
    }
}
