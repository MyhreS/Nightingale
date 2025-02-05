import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack {
                MusicSelector()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.gray.opacity(0.3))
                    .cornerRadius(20)
                    .shadow(radius: 10)

                MusicPlayer()
                    .frame(maxWidth: .infinity, maxHeight: 150)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(20)
                    .padding(0)
                    .shadow(radius: 10)
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
