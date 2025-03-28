import SwiftUI

struct ContentView: View {
    @State private var selectedPlaylist: String = "All"
    
    var body: some View {
        ZStack {
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
                
                ScrollView {
                    VStack(spacing: 16) {
                        Playlist(selectedPlaylist: $selectedPlaylist)
                            .padding(.top, 10)
                            .padding(.bottom, 140)
                    }
                    .padding(.horizontal, 8)
                }
                
                Spacer(minLength: 0)
            }
            
            VStack {
                Spacer()
                MusicPlayer()
                    .padding(.horizontal)
                    .padding(.bottom, 10)
            }
        }
    }
}

#Preview {
    ContentView()
}
