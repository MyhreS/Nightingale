import SwiftUI
import SoundCloud

struct ContentView: View {
    let sc: SoundCloud
    
    var body: some View {
        RootGateView(sc: sc)
    }
}
