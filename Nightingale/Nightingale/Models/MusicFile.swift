import Foundation

struct MusicFile: Identifiable, Codable, Hashable {
    let id: UUID
    let url: URL
    let name: String
    var tag: String
    var played: Bool

    init(url: String, tag: String = "", played: Bool = false) {
        self.id = UUID()
        self.url = URL(fileURLWithPath: url)
        self.name = URL(fileURLWithPath: url).deletingPathExtension().lastPathComponent
        self.tag = tag
        self.played = played
    }
}
