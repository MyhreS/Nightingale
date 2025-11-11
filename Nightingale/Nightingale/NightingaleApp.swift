import SwiftUI
import UIKit

@main
struct NightingaleApp: App {
    @StateObject private var firebaseAPI = FirebaseAPI.shared
    
    init() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(firebaseAPI)
        }
    }
}