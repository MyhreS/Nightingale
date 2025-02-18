import SwiftUI

struct MusicList: View {
    let songs: [MusicFile]

    var body: some View {
        List(songs, id: \.self) { file in
            MusicItem(musicFile: file)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.leading, 0)
    }
}
