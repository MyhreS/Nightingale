import SwiftUI

struct HomePage: View {
    @State private var selectedPlaylist: String = "All"

    var body: some View {
        VStack(spacing: 0) {
            topBar()
            playlistContent()
        }
    }

    func topBar() -> some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    PlaylistsSelector(selectedPlaylist: $selectedPlaylist)
                }
            }
            .frame(maxWidth: .infinity)

            MoreButton()
        }
        .padding()
    }

    func playlistContent() -> some View {
        ScrollView {
            VStack(spacing: 16) {
                Playlist(selectedPlaylist: $selectedPlaylist)
                    .padding(.top, 10)
                    .padding(.bottom, 200)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
