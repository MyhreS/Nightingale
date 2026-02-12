import Foundation
import FirebaseCore
import FirebaseDatabase
import FirebaseStorage

@MainActor
final class FirebaseAPI: ObservableObject {
    static let shared = FirebaseAPI()
    
    private lazy var db = Database.database().reference()
    private lazy var storage = Storage.storage()
    
    
    private init() {
        FirebaseApp.configure()
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
            db.child(path).getData { error, snapshot in
                if let error {
                    cont.resume(throwing: error)
                    return
                }

                guard let snapshot else {
                    cont.resume(throwing: NSError(
                        domain: "FirebaseAPI",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Snapshot was nil"]
                    ))
                    return
                }

                cont.resume(returning: snapshot)
            }
        }
    }
    
    func fetchUsersAllowedFirebaseSongs() async throws -> [String] {
        let snapshot = try await read(path: "usersAllowedFirebaseSongs")

        guard let value = snapshot.value else {
            return []
        }

        if let array = value as? [[String: Any]] {
            return array.compactMap(extractAllowedUserId)
        }

        if let dict = value as? [String: Any] {
            return dict.values.compactMap { item in
                guard let itemDict = item as? [String: Any] else { return nil }
                return extractAllowedUserId(itemDict)
            }
        }

        return []
    }

    private func extractAllowedUserId(_ dict: [String: Any]) -> String? {
        if let id = dict["id"] as? String { return id }
        if let id = dict["id"] as? Int { return String(id) }
        return nil
    }
    
    
    func fetchStorageDownloadURL(path: String) async throws -> URL {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return try await storage.reference(withPath: encodedPath).downloadURL()
    }
}
