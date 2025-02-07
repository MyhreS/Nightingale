import Foundation

struct MusicFile: Identifiable, Codable, Hashable {
    let id: UUID
    let url: URL
    let name: String
    var tag: String
    var played: Bool

    init(url: URL, tag: String = "", played: Bool = false) {
        self.id = UUID()
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.tag = tag
        self.played = played
    }
}
