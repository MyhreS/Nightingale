import Foundation
import AVFoundation

struct MusicFile: Identifiable, Codable, Hashable {
    // Required properties that must always exist
    let id: String
    let url: URL
    let name: String
    var startTime: Double
    var duration: Double
    var played: Bool
    
    // Optional properties with default values
    var tag: String = ""
    
    enum CodingKeys: String, CodingKey {
        case id, url, name, duration, tag, played, startTime
        // Add new coding keys here when adding properties
    }
    
    init(url: URL) {
        self.id = UUID().uuidString
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.startTime = 0.0
        self.duration = 0.0
        self.played = false
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required properties (must exist)
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        name = try container.decode(String.self, forKey: .name)
        duration = try container.decode(Double.self, forKey: .duration)
        
        // Optional properties (use default values if not found)
        tag = try container.decodeIfPresent(String.self, forKey: .tag) ?? ""
        played = try container.decodeIfPresent(Bool.self, forKey: .played) ?? false
        startTime = try container.decodeIfPresent(Double.self, forKey: .startTime) ?? 0.0
        // Add new property decoding here
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all properties
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(name, forKey: .name)
        try container.encode(duration, forKey: .duration)
        try container.encode(tag, forKey: .tag)
        try container.encode(played, forKey: .played)
        try container.encode(startTime, forKey: .startTime)
        // Add new property encoding here
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MusicFile, rhs: MusicFile) -> Bool {
        return lhs.id == rhs.id
    }
}
