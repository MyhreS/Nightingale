import SwiftUI

struct LandingPage: View {
    @StateObject private var auth = SoundCloudAuth.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient (
                    colors: [.orange.opacity(0.8), .orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing,
                )
                .ignoresSafeArea()
                
                Button(action: loadTracks) {
                    HStack {
                        Text("Load tracks")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        
    }
    

    private func loadTracks() {
        
    }
}
