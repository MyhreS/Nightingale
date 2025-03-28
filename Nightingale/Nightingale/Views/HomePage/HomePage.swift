
import SwiftUI

struct HomePage: View {
    @State private var selectedPlaylist: String = "All"

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        PlaylistsSelector(selectedPlaylist: $selectedPlaylist)
                    }
                }
                .frame(maxWidth: .infinity)
                RemoveButton()
                AddButton()
            }
            .padding()

            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 16) {
                        Playlist(selectedPlaylist: $selectedPlaylist)
                            .padding(.top, 10)
                            .padding(.bottom, 200) // Extra space for player + drawer
                    }
                    .padding(.horizontal, 0)
                }

                LinearGradient(
                    gradient: Gradient(colors: [.clear, Color.black.opacity(0.5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
        }
    }
}
