import SwiftUI

struct CurrentQueued: View {
    @ObservedObject var musicQueue = MusicQueue.shared
    
    var body: some View {
        HStack(spacing: 10) {
            // Music icon (squircle)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(musicQueue.currentSong != nil ? Color.green.opacity(0.8) : Color.gray.opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(musicQueue.currentSong != nil ? .white : .gray)
            }

            if let song = musicQueue.currentSong {
                Text(song.name)
                    .font(.headline)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("No song queued")
                    .font(.headline)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(5)
    }
}
