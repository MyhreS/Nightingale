import Foundation
import FirebaseCore
import FirebaseAnalytics

@MainActor
final class FirebaseAPI: ObservableObject {
    static let shared = FirebaseAPI()
    
    private init() {
        FirebaseApp.configure()
    }
    
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }
}