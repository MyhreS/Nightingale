import SwiftUI

struct HomePage: View {
    @State private var selectedPlaylist: String = "All"

    var body: some View {
        VStack(spacing: 0) {
            TopBar(selectedPlaylist: $selectedPlaylist)
            GeometryReader { geo in
                ScrollView {
                    Content(selectedPlaylist: $selectedPlaylist)
                }
                .mask(
                    bottomFadeMask(height: geo.size.height)
                        .frame(height: geo.size.height)
                )
            }
        }
    }
}

func bottomFadeMask(height: CGFloat) -> LinearGradient {
    let stops = [
        // Bottom is fully invisible
        Gradient.Stop(color: .clear, location: 0),
        // 10px up = almost invisible
        Gradient.Stop(color: Color.black.opacity(0.05), location: 0.2),
        // Top = fully visible
        Gradient.Stop(color: .black, location: 0.4)
    ]
    return LinearGradient(
        gradient: Gradient(stops: stops),
        startPoint: .bottom,
        endPoint: .top
    )
}

struct TopBar: View {
    @Binding var selectedPlaylist: String
    var body: some View {
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
    }
}

struct Content: View {
    @Binding var selectedPlaylist: String
    var body: some View {
        VStack(spacing: 16) {
            Playlist(selectedPlaylist: $selectedPlaylist)
                .padding(.top, 10)
                .padding(.bottom, 200)
        }
        .frame(maxWidth: .infinity)
    }
}
