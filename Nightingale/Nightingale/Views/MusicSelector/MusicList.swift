import SwiftUI

struct MusicList: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared
    
    var body: some View {
        List(musicLibrary.musicFiles, id: \.self) { file in
            MusicItem(file: file)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden) // Ensure List container background is transparent
    }
}
