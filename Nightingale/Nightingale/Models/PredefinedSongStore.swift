import Foundation

enum SongGroup: String, Codable, CaseIterable, Identifiable {
    case goal
    case warmup
    case intro
    case fun
    
    var id: String { rawValue}
    
    var displayName: String {
        switch self {
        case .goal: return "Goal"
        case .warmup: return "Warm-up"
        case .intro: return "Intro"
        case .fun: return "Fun"
        }
    }
}

struct PredefinedSong: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let artworkURL: String
    let duration: Int
    let playbackUrl: String
    let linkToSong: String
    let linkToArtist: String
    let artistName: String
    let group: SongGroup
    let startSeconds: Int
    
}

enum PredefinedSongStore {
    static func loadPredefinedSongs() -> [PredefinedSong] {
        guard let url = Bundle.main.url(forResource: "predefined_songs", withExtension: "json") else {
            return []
        }
        
        guard let data = try? Data(contentsOf: url) else {
            return []
        }
        
        let decoder = JSONDecoder()
        return (try? decoder.decode([PredefinedSong].self, from: data)) ?? []
    }
}
