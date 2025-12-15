import SwiftUI

struct RootGateView: View {
    @StateObject private var connectivity = Connectivity()
    
    var body: some View {
        Group {
            if connectivity.isOnline {
                AuthGateView()
            } else {
                NoInternetView()
            }
        }
        .environmentObject(connectivity)
    }
}

