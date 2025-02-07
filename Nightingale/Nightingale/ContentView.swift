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
        }
    }
}

#Preview {
    ContentView()
}
