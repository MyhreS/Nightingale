import SwiftUI

struct LandingPage: View {
    @StateObject private var auth = SoundCloudAuth.shared
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                VStack(spacing: 16) {
                }
                .padding()
            }
        }
        
    }
    

    private func toggleTab() {
        selectedTab = (selectedTab == .home) ? .settings : .home
    }
}
