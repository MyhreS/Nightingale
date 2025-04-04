import SwiftUI

struct MusicItem: View {
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @ObservedObject private var audioQueue = AudioQueue.shared
    
    @Binding var song: Song
    
    private var queued: Bool {
        if (song.id == audioQueue.song?.id) {
            return true
        }
        return false
    }
    
    var body: some View {
            Button(action: {
                addToQueue(song)
                provideHapticFeedback()
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 60, height: 60)
                        Image(systemName: "music.note")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                    }


                    Text(song.fileName)
                        .font(queued ? .body.weight(.bold) : .body)
                        .foregroundColor(queued ? .blue : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    EditButton(song: $song)
                }
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
        }


    private func addToQueue(_ song: Song) {
        print("[MusicItem] 🎵 Adding song to queue: \(song.fileName), startTime: \(song.startTime)")
        audioQueue.addSong(song)
    }
}
