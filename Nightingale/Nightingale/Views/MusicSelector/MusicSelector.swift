import SwiftUI

struct MusicSelector: View {
    @ObservedObject var musicLibrary = MusicLibrary.shared // Access shared music library

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Your Music")
                .font(.headline)
                .fontWeight(.bold)

            if musicLibrary.musicFiles.isEmpty {
                Text("No music added yet. Go to settings to add some!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                List(musicLibrary.musicFiles, id: \.self) { file in
                    Text(file.lastPathComponent)
                        .font(.body)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
