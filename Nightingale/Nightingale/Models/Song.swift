import Foundation

typealias SongGroup = String

extension SongGroup {
    var displayName: String {
        guard !self.isEmpty else { return "" }
        return self.prefix(1).uppercased() + self.dropFirst()
    }
}

enum StreamingSource: String, Codable {
    case soundcloud
    case firebase
    case local
}

struct Song: Codable, Identifiable, Equatable {
    let songId: String
    var name: String
    var artistName: String
    let originalSongName: String
    let originalSongArtistName: String
    let originalArtWorkUrl: String
    let artworkURL: String
    let duration: Int
    let playbackUrl: String
    let linkToSong: String
    let linkToArtist: String
    let group: SongGroup
    var startSeconds: Int
    let streamingSource: StreamingSource
    
    var id: String { "\(songId)-\(group)" }
    
    enum CodingKeys: String, CodingKey {
        case songId = "id"
        case name, artistName, originalSongName, originalSongArtistName
        case originalArtWorkUrl, artworkURL, duration, playbackUrl
        case linkToSong, linkToArtist, group, startSeconds, streamingSource
    }
}

extension Array where Element == Song {
    var uniqueGroups: [SongGroup] {
        var seen = Set<SongGroup>()
        var result = [SongGroup]()
        for song in self {
            if !seen.contains(song.group) {
                seen.insert(song.group)
                result.append(song.group)
            }
        }
        return result
    }
}
