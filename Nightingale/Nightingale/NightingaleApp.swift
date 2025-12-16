import SwiftUI
import UIKit
import SoundCloud

@main
struct NightingaleApp: App {
    @StateObject private var firebaseAPI = FirebaseAPI.shared
    private let sc: SoundCloud
    private let streamCache: StreamDetailsCache
    
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
        
        let secrets = SecretsKeeper.shared
        let config = SoundCloud.Config(
            clientId: secrets.getClientId(),
            clientSecret: secrets.getClientSecret(),
            redirectURI: secrets.getRedirectUri()
        )
        let soundcloud = SoundCloud(config)
        self.sc = soundcloud
        self.streamCache = StreamDetailsCache(sc: soundcloud, firebaseAPI: FirebaseAPI.shared)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(sc: sc, streamCache: streamCache)
                .preferredColorScheme(.dark)
                .environmentObject(firebaseAPI)
        }
    }
}