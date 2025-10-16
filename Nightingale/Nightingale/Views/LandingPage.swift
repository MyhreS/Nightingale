import SwiftUI

struct LandingPage: View {

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [.orange.opacity(0.8), .orange.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ).ignoresSafeArea()

                VStack(spacing: 16) {
                }
                .padding()
            }
            .navigationTitle("Discover")
        }
    }
}
