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
    
    func fetchPredefinedSongs() async throws -> [Song] {
        let snapshot = try await read(path: "predefined_songs")

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
    
    func fetchStorageDownloadURL(path: String) async throws -> URL {
        try await storage.reference(withPath: path).downloadURL()
    }
}
