import SwiftUI
import SoundCloud

struct RootGateView: View {
    let sc: SoundCloud
    @StateObject private var connectivity = Connectivity()
    
    var body: some View {
        Group {
            if connectivity.isOnline {
                AuthGateView(sc: sc)
            } else {
                NoInternetView()
            }
        }
        .environmentObject(connectivity)
    }
}

