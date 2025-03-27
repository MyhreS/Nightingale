import SwiftUI

struct ContentView: View {
    @State private var selectedPlaylist: String = "All"
    
    var body: some View {
        ZStack {
            Color(red: 0.02, green: 0.05, blue: 0.01)
                .ignoresSafeArea()
            
            // 2. Green → Black gradient from topTrailing
            LinearGradient(
                gradient: Gradient(colors: [.gray.opacity(0.5), .black]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .blur(radius: 150)
            .ignoresSafeArea()
            
            // 3. Grain overlay
            Canvas { context, size in
                for _ in 0..<2000 {
                    let x = CGFloat.random(in: 0...size.width)
                    let y = CGFloat.random(in: 0...size.height)
                    
                    // More grain on top-right fading to bottom-left
                    let horizontalFactor = x / size.width
                    let verticalFactor = y / size.height
                    let bias = (horizontalFactor + (1 - verticalFactor)) / 2
                    
                    let opacity = Double.random(in: 0.02...0.05) * bias
                    
                    context.fill(
                        Path(ellipseIn: CGRect(x: x, y: y, width: 1.2, height: 1.2)),
                        with: .color(Color.white.opacity(opacity))
                    )
                }
            }
            .ignoresSafeArea()
            .blendMode(.overlay)
            
            VStack(spacing: 0) {
                // Fixed header/footer
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
                .background(Color.black.opacity(0.3).blur(radius: 10))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.white.opacity(0.1)),
                    alignment: .bottom
                )
                
                // Scrollable Playlist
                ScrollView {
                    VStack(spacing: 16) {
                        Playlist(selectedPlaylist: $selectedPlaylist)
                            .padding(.top, 10)
                            .padding(.bottom, 140) // leave space for player
                    }
                    .padding(.horizontal, 8)
                }
                
                Spacer(minLength: 0)
            }
            
            // Floating music player on top
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
