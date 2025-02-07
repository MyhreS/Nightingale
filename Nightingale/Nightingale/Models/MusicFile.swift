import Foundation

struct MusicFile: Identifiable, Codable, Hashable {
    let id: UUID // Unique identifier for each file
    let url: URL
    let name: String
    let tag: String

    init(url: String, tag: String = "") {
        self.id = UUID()
        self.url = URL(fileURLWithPath: url) // Convert string to URL
        self.name = URL(fileURLWithPath: url).deletingPathExtension().lastPathComponent // Extract name from URL
        self.tag = tag
    }

    // Conformance to `Hashable` via synthesized implementation
    static func == (lhs: MusicFile, rhs: MusicFile) -> Bool {
        lhs.id == rhs.id // Two MusicFiles are equal if their IDs are the same
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id) // Hash by ID
    }
}
