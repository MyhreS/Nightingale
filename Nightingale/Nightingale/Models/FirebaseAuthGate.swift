import FirebaseAuth
import Foundation

@MainActor
final class FirebaseAuthGate {
    static let shared = FirebaseAuthGate()

    private init() {}

    func ensureSignedIn() async throws {
        if Auth.auth().currentUser != nil { return }
        _ = try await Auth.auth().signInAnonymously()
    }
}
