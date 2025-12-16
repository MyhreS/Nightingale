import Foundation

enum SongGroup: String, Codable, CaseIterable, Identifiable {
    case faceoff
    case penalty
    case goal
    case crowd
    case intro
    
    var id: String { rawValue }
    
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

enum StreamingSource: String, Codable {
    case soundcloud
    case firebase
}

struct Song: Codable, Identifiable, Equatable {
    let songId: String
    let name: String
    let artistName: String
    let originalSongName: String
    let originalSongArtistName: String
    let originalArtWorkUrl: String
    let artworkURL: String
    let duration: Int
    let playbackUrl: String
    let linkToSong: String
    let linkToArtist: String
    let group: SongGroup
    let startSeconds: Int
    let streamingSource: StreamingSource
    
    var id: String { "\(songId)-\(group.rawValue)" }
    
    enum CodingKeys: String, CodingKey {
        case songId = "id"
        case name, artistName, originalSongName, originalSongArtistName
        case originalArtWorkUrl, artworkURL, duration, playbackUrl
        case linkToSong, linkToArtist, group, startSeconds, streamingSource
    }
}
