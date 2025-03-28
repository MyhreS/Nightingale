import SwiftUI

struct ResetPlayedStatusButton: View {
    @State private var success = false

    var body: some View {
        Button(action: {
            for var song in MusicLibrary.shared.songs {
                song.played = false
                MusicLibrary.shared.editMusicFile(song)
            }

            withAnimation {
                success = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    success = false
                }
            }
        }) {
            HStack {
                if success {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Status Reset!")
                } else {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Played Status")
                }
            }
            .foregroundColor(success ? .green : .blue)
            .padding()
            .background(success ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
        }
    }
}
