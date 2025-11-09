import Foundation

struct PredefinedSong: Codable, Identifiable {
    let id: String
    let name: String
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
