import SwiftUI
import UIKit

@main
struct NightingaleApp: App {
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    print("[App] onOpenURL received:", url.absoluteString)
                    SoundCloudAuth.shared.handleRedirect(url: url)
                }
                .preferredColorScheme(.dark)
        }
    }
}
