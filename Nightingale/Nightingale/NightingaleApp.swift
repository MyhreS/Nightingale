import SwiftUI

@main
struct NightingaleApp: App {
    init() {
        // ✅ Prevent screen from turning off
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
