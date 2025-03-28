import SwiftUI

struct MusicItem: View {
    //@ObservedObject var musicQueue = MusicQueue.shared // Shared music queue
    @State private var queued = false;
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @Binding var song: Song
    
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


    private func addToQueue(_ musicFile: Song) {
        print("[MusicItem] 🎵 Adding song to queue: \(musicFile.fileName), startTime: \(musicFile.startTime)")
        queued = true;
        // PlayerManager.shared.stop()
        //musicQueue.addToQueue(musicFile)
    }
}
