import SwiftUI

struct ContentView: View {
    @State private var selectedPlaylist: String = "All"

    var body: some View {
        ZStack {
        
            Color(UIColor.darkGray).opacity(0.3)
                .ignoresSafeArea()
            
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
                                .padding(.bottom, 160)
                        }
                        .padding(.horizontal, 0)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(spacing: 0) {
                Spacer()
                MusicPlayer()
                    .padding(.horizontal)
                    .padding(.bottom, 0)

                BottomDrawer()
                    .padding(.bottom, 25)

            }
        }
        .ignoresSafeArea(edges: .bottom)
        
    }
}

#Preview {
    ContentView()
}
