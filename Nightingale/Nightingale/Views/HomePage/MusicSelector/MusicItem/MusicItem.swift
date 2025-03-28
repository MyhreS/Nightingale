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
                // Music icon (squircle)
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconBackgroundColor())
                        .frame(width: 40, height: 40)

                    Image(systemName: "music.note")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(iconForegroundColor())
                }

                // Song name
                Text(song.fileName)
                    .font(.body)
                    .lineLimit(nil)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                EditButton(song: $song)
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(queued ? Color.green.opacity(0.2) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        
    }


    private func iconBackgroundColor() -> Color {
        if queued {
            return Color.green.opacity(0.8)
        } else if song.played {
            return Color.gray.opacity(0.3)
        } else {
            return Color.blue.opacity(0.2)
        }
    }


    private func iconForegroundColor() -> Color {
        if queued {
            return .white
        } else if song.played {
            return .gray
        } else {
            return .blue
        }
    }


    private func addToQueue(_ musicFile: Song) {
        print("[MusicItem] 🎵 Adding song to queue: \(musicFile.fileName), startTime: \(musicFile.startTime)")
        queued = true;
        // PlayerManager.shared.stop()
        //musicQueue.addToQueue(musicFile)
    }
}
