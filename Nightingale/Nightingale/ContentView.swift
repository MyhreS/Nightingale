import SwiftUI

struct ContentView: View {
    @StateObject private var appAuth = SoundCloudAppAuth.shared
    
    var body: some View {
        LandingPage()
    }
    

    
}

#Preview {
    ContentView()
}
