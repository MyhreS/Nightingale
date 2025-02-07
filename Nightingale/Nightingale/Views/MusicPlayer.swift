import SwiftUI

struct MusicPlayer: View {
    var body: some View {
        VStack {
            Text("Music Player")
        }
        .frame(maxWidth: .infinity, maxHeight: 150)
        .padding(10)
        .background(Color.blue.opacity(0.5))
        .cornerRadius(20)

        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1) // Border
        )
    }
}
