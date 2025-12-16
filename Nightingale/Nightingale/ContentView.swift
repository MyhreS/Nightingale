import SwiftUI
import SoundCloud

struct ContentView: View {
    let sc: SoundCloud
    let streamCache: StreamDetailsCache
    
    var body: some View {
        RootGateView(sc: sc, streamCache: streamCache)
    }
}
