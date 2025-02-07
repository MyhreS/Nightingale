import SwiftUI

struct CurrentQueued: View {
    @ObservedObject var musicQueue = MusicQueue.shared // Observe the queue

    var body: some View {
        HStack(spacing: 10) {
            // Music icon (squircle)
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(musicQueue.nextSong != nil ? Color.green.opacity(0.8) : Color.gray.opacity(0.2)) // ✅ Gray if no song
                    .frame(width: 40, height: 40)

                Image(systemName: "music.note")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(musicQueue.nextSong != nil ? .white : .gray) // ✅ Gray if no song
            }

            // Song name or "Select a song"
            Text(musicQueue.nextSong?.name ?? "Select a song") // ✅ Handle empty queue
                .font(.body)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(5)
        .frame(maxWidth: .infinity) // Expand button to fill available space
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
        )
    }
}
