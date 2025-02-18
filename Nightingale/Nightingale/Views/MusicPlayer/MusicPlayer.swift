import SwiftUI

struct MusicPlayer: View {
    var body: some View {
        CustomCard {
            HStack(spacing: 10) {
                CurrentQueued()
                PlayPauseButton()
            }
            .frame(maxWidth: .infinity, maxHeight: 70)
        }
        .padding(10)
    }
}
