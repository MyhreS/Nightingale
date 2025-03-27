import SwiftUI

@main
struct NightingaleApp: App {
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
            .preferredColorScheme(.dark)
        }
    }
}
