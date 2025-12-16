import SwiftUI
import UIKit
import SoundCloud

@main
struct NightingaleApp: App {
    @StateObject private var firebaseAPI = FirebaseAPI.shared
    private let sc: SoundCloud
    
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
        
        let secrets = SecretsKeeper.shared
        let config = SoundCloud.Config(
            clientId: secrets.getClientId(),
            clientSecret: secrets.getClientSecret(),
            redirectURI: secrets.getRedirectUri()
        )
        self.sc = SoundCloud(config)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(sc: sc)
                .preferredColorScheme(.dark)
                .environmentObject(firebaseAPI)
        }
    }
}