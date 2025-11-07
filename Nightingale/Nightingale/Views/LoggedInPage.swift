import SwiftUI
import SoundCloud

struct LoggedInPage: View {
    let sc: SoundCloud
    @State private var tracks: [Track] = []
    @State private var loading = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Hello soundcloud")
        }
    }
}
