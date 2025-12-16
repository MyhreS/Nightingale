import SwiftUI
import SoundCloud

struct RootGateView: View {
    let sc: SoundCloud
    let streamCache: StreamDetailsCache
    @StateObject private var connectivity = Connectivity()
    
    var body: some View {
        Group {
            if connectivity.isOnline {
                AuthGateView(sc: sc, streamCache: streamCache)
            } else {
                NoInternetView()
            }
        }
        .environmentObject(connectivity)
    }
}

