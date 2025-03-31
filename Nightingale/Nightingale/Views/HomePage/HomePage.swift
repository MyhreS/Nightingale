import SwiftUI

struct HomePage: View {
    @State private var selectedPlaylist: String = "All"
    @State private var scrollOffset: CGFloat = 0

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
            .overlay(
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 1)
                    .opacity(scrollOffset > 20 ? 1 : 0),
                alignment: .bottom
            )
        }

    func playlistContent() -> some View {
        ScrollView {
            ZStack(alignment: .top) {
                ScrollDetector(scrollOffset: $scrollOffset)
                    .frame(height: 0)
                
                VStack(spacing: 16) {
                    Playlist(selectedPlaylist: $selectedPlaylist)
                        .padding(.top, 10)
                        .padding(.bottom, 200)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .coordinateSpace(name: "scrollView")
    }
}

struct ScrollDetector: View {
    @Binding var scrollOffset: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scrollView")).minY)
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    withAnimation(.easeInOut(duration: 0.05)) {
                        scrollOffset = -value
                    }
                }
        }
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
