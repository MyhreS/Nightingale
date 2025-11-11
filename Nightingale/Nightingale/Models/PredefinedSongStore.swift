import Foundation

enum SongGroup: String, Codable, CaseIterable, Identifiable {
    case faceoff
    case penalty
    case goal
    case crowd
    case intro
    
    var id: String { rawValue}
    
    var displayName: String {
        switch self {
        case .faceoff: return "Face-off"
        case .penalty: return "Penalty"
        case .goal: return "Goal"
        case .crowd: return "Crowd"
        case .intro: return "Intro"
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
    let goPlussSong: Bool
    
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
