import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                MusicSelector()

                MusicPlayer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Toolbar()
                }
            }
            .background(Color.blue.opacity(0.1))
        }
    }
}

#Preview {
    ContentView()
}
