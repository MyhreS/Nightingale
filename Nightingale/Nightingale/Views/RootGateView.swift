import SwiftUI
import SoundCloud

struct RootGateView: View {
    let sc: SoundCloud
    @StateObject private var connectivity = Connectivity()
    
    var body: some View {
        AuthGateView(sc: sc)
            .environmentObject(connectivity)
    }
}
