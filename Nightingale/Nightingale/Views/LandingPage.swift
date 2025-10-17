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
                
                Button(action: searchSomething) {
                    Text("Fetch Track Info")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 24)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .orange.opacity(0.4), radius: 6, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding()
            }
            .navigationTitle("Discover")
        }
    }
    
    func searchSomething() {
        Task {
            do {
                let tracks = try await SoundCloud.search(query: "Goo Goo Dolls Slide", limit: 5)
                print("Found \(tracks.count) tracks:")
                if let first = tracks.first {
                    TrackPrinter.printSummary(for: first)
                }
            } catch {
                print("Error: \(error.localizedDescription)")
            }
        }
    }
}
