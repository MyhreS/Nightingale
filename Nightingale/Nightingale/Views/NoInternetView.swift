import SwiftUI

struct NoInternetView: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Spacer()
                    .frame(height: 20)
                
                VStack(spacing: 16) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 64, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Nightingale")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Game Day Music, Simplified")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Color(white: 0.6))
                }
                
                VStack(spacing: 20) {
                    FeatureCard(
                        icon: "wifi.slash",
                        title: "No Internet Connection",
                        description: "You must be connected to the internet to use this app."
                    )
                }
                .padding(.horizontal, 24)
                
                
                Spacer()
                    .frame(height: 20)
            }
        }
        .scrollIndicators(.hidden)
    }
}
