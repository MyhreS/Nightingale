import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage

@MainActor
final class FirebaseAPI: ObservableObject {
    static let shared = FirebaseAPI()
    
    private lazy var db = Database.database().reference()
    private lazy var storage = Storage.storage()

    @Published var addLocalMusicEnabled = false
    @Published var emailLoginEnabled = true
    @Published var soundcloudLoginEnabled = false

    private init() {
        FirebaseApp.configure()
    }

    func fetchFeatureFlags() async {
        do {
            try await FirebaseAuthGate.shared.ensureSignedIn()
            let snapshot = try await read(path: "featureFlags")
            guard let dict = snapshot.value as? [String: Any] else { return }
            addLocalMusicEnabled = dict["addLocalMusicButton"] as? Bool ?? false
            emailLoginEnabled = dict["emailLogin"] as? Bool ?? true
            soundcloudLoginEnabled = dict["soundcloudLogin"] as? Bool
                ?? dict["soundcloudSongs"] as? Bool
                ?? false
        } catch {
            print("Failed to fetch feature flags: \(error)")
        }
    }
    
    func fetchSoundcloudSongs() async throws -> [Song] {
        return try await fetchSongs(name: "soundcloudSongs")
    }
    
    func fetchFirebaseSongs() async throws -> [Song] {
        return try await fetchSongs(name: "firebaseSongs")
    }
    
    private func fetchSongs(name: String) async throws -> [Song] {
        let snapshot = try await read(path: name)

        guard let value = snapshot.value else {
            return []
        }

        if let dict = value as? [String: Any] {
            let values = Array(dict.values)
            let data = try JSONSerialization.data(withJSONObject: values)
            return try JSONDecoder().decode([Song].self, from: data)
        }

        if let array = value as? [Any] {
            let data = try JSONSerialization.data(withJSONObject: array)
            return try JSONDecoder().decode([Song].self, from: data)
        }

        return []
    }
    
    private func read(path: String) async throws -> DataSnapshot {
        try await withCheckedThrowingContinuation { cont in
            db.child(path).observeSingleEvent(of: .value) { snapshot in
                cont.resume(returning: snapshot)
            } withCancel: { error in
                cont.resume(throwing: error)
            }
        }
    }
    
    func fetchAllowedFirebaseSongsEmails() async throws -> [String] {
        let snapshot = try await read(path: "usersAllowedFirebaseSongs")

        guard let value = snapshot.value else {
            return []
        }

        if let array = value as? [[String: Any]] {
            return array.compactMap(extractAllowedEmail)
        }

        if let dict = value as? [String: Any] {
            return dict.values.compactMap { item in
                guard let itemDict = item as? [String: Any] else { return nil }
                return extractAllowedEmail(itemDict)
            }
        }

        return []
    }

    private func extractAllowedEmail(_ dict: [String: Any]) -> String? {
        if let email = dict["email"] as? String { return email }
        if let id = dict["id"] as? String { return id }
        return nil
    }
    
    
    func fetchStorageDownloadURL(path: String) async throws -> URL {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return try await storage.reference(withPath: encodedPath).downloadURL()
    }
}
