import SwiftUI
import SoundCloud

struct AuthGateView: View {
    let sc: SoundCloud

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            MainPage(sc: sc)
        }
    }
}
