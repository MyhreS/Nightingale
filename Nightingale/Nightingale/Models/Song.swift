import Foundation
import AVFoundation

struct Song: Identifiable, Codable, Hashable {
    let id: String
    let from: URL
    let fileName: String // ✅ Store only the file name
    var startTime: Double
    var duration: Double
    var played: Bool

    /// ✅ Compute the full URL dynamically
    var url: URL {
        return MusicStorage.shared.getStorageURL(for: fileName)
    }

    enum CodingKeys: String, CodingKey {
        case id, from, fileName, duration, played, startTime
    }
    
    init(from: URL, url: URL) {
        self.id = UUID().uuidString
        self.from = from
        self.fileName = url.lastPathComponent // ✅ Store just the file name
        self.startTime = 0.0
        self.played = false

        // Get duration using AVFoundation
        if let audioAsset = try? AVAudioFile(forReading: url) {
            self.duration = Double(audioAsset.length) / audioAsset.processingFormat.sampleRate
            print("✅ Set duration for \(fileName): \(self.duration) seconds")
        } else {
            print("⚠️ Could not get duration for \(fileName), defaulting to 0")
            self.duration = 0.0
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        from = try container.decode(URL.self, forKey: .from)
        fileName = try container.decode(String.self, forKey: .fileName) // ✅ Decode fileName instead of url
        duration = try container.decode(Double.self, forKey: .duration)
        played = try container.decodeIfPresent(Bool.self, forKey: .played) ?? false
        startTime = try container.decodeIfPresent(Double.self, forKey: .startTime) ?? 0.0
    }
    
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(from, forKey: .from)
        try container.encode(fileName, forKey: .fileName) // ✅ Store fileName, not url
        try container.encode(duration, forKey: .duration)
        try container.encode(played, forKey: .played)
        try container.encode(startTime, forKey: .startTime)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Song, rhs: Song) -> Bool {
        return lhs.id == rhs.id
    }
}
