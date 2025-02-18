import Foundation

struct MusicFile: Identifiable, Codable, Hashable {
    // Required properties that must always exist
    let id: UUID
    let url: URL
    let name: String
    
    // Optional properties with default values
    var tag: String = ""
    var played: Bool = false
    var startTime: Double = 0.0
    // Add new properties here with default values
    
    enum CodingKeys: String, CodingKey {
        case id, url, name, tag, played, startTime
        // Add new coding keys here when adding properties
    }
    
    init(url: URL, tag: String = "", played: Bool = false, startTime: Double = 0.0) {
        self.id = UUID()
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.tag = tag
        self.played = played
        self.startTime = startTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required properties (must exist)
        id = try container.decode(UUID.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        name = try container.decode(String.self, forKey: .name)
        
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
        try container.encode(tag, forKey: .tag)
        try container.encode(played, forKey: .played)
        try container.encode(startTime, forKey: .startTime)
        // Add new property encoding here
    }
}
