import Foundation

class AudioQueue : ObservableObject {
    static let shared = AudioQueue()
    
    @Published var song: Song? = nil
    var playOnSelect: Bool = true
    
    func addSong(_ newSong: Song) {
        song = newSong
    }
}

