import Foundation

class PlaylistsManager: ObservableObject {
    static let shared = PlaylistsManager()
    @Published var playlists: [String] = []
    private let playlistsKey = "SavedPlaylists"
    
    private init() {
        loadPlaylistsFromConfig()
    }
    
    private func updatePlaylistsInConfig() {
        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: playlistsKey)
            UserDefaults.standard.synchronize()
        } catch {
            fatalError("❌ CRITICAL ERROR: Failed to update playlist config: \(error.localizedDescription)")
        }
    }
    
    private func loadPlaylistsFromConfig() {
        guard let data = UserDefaults.standard.data(forKey: playlistsKey) else {
            print("⚠️ No playlists found in UserDefaults. Initializing empty list.")
            playlists = []  // Start with an empty list
            return
        }

        do {
            playlists = try JSONDecoder().decode([String].self, from: data)
        } catch {
            print("❌ Error: Failed to load playlist config. Resetting playlists.")
            playlists = []  // Reset to an empty list instead of crashing
            UserDefaults.standard.removeObject(forKey: playlistsKey)  // Remove corrupt data
        }
    }
    
    func addPlaylist(_ name: String) {
        guard !playlists.contains(name) else { return }
        playlists.append(name)
        updatePlaylistsInConfig()
        print("Created playlist: \(name)")
        
    }
    
    func removePlaylist(_ name: String) {
        if let index = playlists.firstIndex(of: name) {
            playlists.remove(at: index)
            updatePlaylistsInConfig()
        }
        print("Remove playlist: \(name)")
    }

    
    
    
    
    
}
