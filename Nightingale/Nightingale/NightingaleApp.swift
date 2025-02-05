import SwiftUI
import FirebaseCore

// Add AppDelegate for Firebase initialization
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        let options = FirebaseOptions(
            googleAppID: FirebaseConfig.googleAppID,
            gcmSenderID: FirebaseConfig.gcmSenderID
        )
        options.apiKey = FirebaseConfig.apiKey
        options.projectID = FirebaseConfig.projectID
        options.storageBucket = FirebaseConfig.storageBucket
        
        FirebaseApp.configure(options: options)
        return true
    }
}

@main
struct NightingaleApp: App {
    // Register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
