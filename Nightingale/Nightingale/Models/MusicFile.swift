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
    
    enum CodingKeys: String, CodingKey {
        case id, url, name, duration, played, startTime
    }
    
    init(url: URL) {
        self.id = UUID().uuidString
        self.url = url
        self.name = url.deletingPathExtension().lastPathComponent
        self.startTime = 0.0
        self.played = false
        
        // Get duration using AVFoundation
        if let audioAsset = try? AVAudioFile(forReading: url) {
            self.duration = Double(audioAsset.length) / audioAsset.processingFormat.sampleRate
            print("✅ Set duration for \(name): \(self.duration) seconds")
        } else {
            print("⚠️ Could not get duration for \(name), defaulting to 0")
            self.duration = 0.0
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Required properties (must exist)
        id = try container.decode(String.self, forKey: .id)
        url = try container.decode(URL.self, forKey: .url)
        name = try container.decode(String.self, forKey: .name)
        duration = try container.decode(Double.self, forKey: .duration)
        played = try container.decodeIfPresent(Bool.self, forKey: .played) ?? false
        startTime = try container.decodeIfPresent(Double.self, forKey: .startTime) ?? 0.0
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode all properties
        try container.encode(id, forKey: .id)
        try container.encode(url, forKey: .url)
        try container.encode(name, forKey: .name)
        try container.encode(duration, forKey: .duration)
        try container.encode(played, forKey: .played)
        try container.encode(startTime, forKey: .startTime)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MusicFile, rhs: MusicFile) -> Bool {
        return lhs.id == rhs.id
    }
}
