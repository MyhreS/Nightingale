import Foundation

class PlaylistManager: ObservableObject {
    static let shared = PlaylistManager()
    
    @Published private(set) var playlists: [String: Set<String>] = [:] // playlist name -> set of file IDs
    private let storageKey = "SavedPlaylists"
    private let musicLibrary = MusicLibrary.shared
    
    private init() {
        loadPlaylists()
    }
    
    /// Creates a new playlist
    func createPlaylist(_ name: String) -> Bool {
        print("🎵 Creating playlist: \(name)")
        guard !name.isEmpty && !playlists.keys.contains(name) else {
            print("❌ Invalid playlist name or playlist already exists")
            return false
        }
        
        playlists[name] = Set<String>()
        savePlaylists()
        print("✅ Created playlist: \(name)")
        return true
    }
    
    /// Adds a song to a playlist
    func addSongToPlaylist(songId: String, playlist: String) {
        print("🎵 Adding song \(songId) to playlist: \(playlist)")
        if !playlists.keys.contains(playlist) {
            print("📝 Creating new playlist: \(playlist)")
            playlists[playlist] = Set<String>()
        }
        
        playlists[playlist]?.insert(songId)
        savePlaylists()
        print("✅ Added song to playlist")
    }
    
    /// Removes a song from a playlist
    func removeSongFromPlaylist(songId: String, playlist: String) {
        print("🗑️ Removing song \(songId) from playlist: \(playlist)")
        playlists[playlist]?.remove(songId)
        
        // If playlist is empty, consider removing it
        if let songs = playlists[playlist], songs.isEmpty {
            print("📝 Removing empty playlist: \(playlist)")
            playlists.removeValue(forKey: playlist)
        }
        
        savePlaylists()
        print("✅ Removed song from playlist")
    }
    
    /// Gets all songs in a playlist
    func songsInPlaylist(_ playlist: String) -> [MusicFile] {
        guard let songIds = playlists[playlist] else { return [] }
        return musicLibrary.songs.filter { songIds.contains($0.id) }
    }
    
    /// Gets all songs not in any playlist
    func untaggedSongs() -> [MusicFile] {
        let allPlaylistSongs = Set(playlists.values.flatMap { $0 })
        return musicLibrary.songs.filter { !allPlaylistSongs.contains($0.id) }
    }
    
    /// Gets the playlist a song is in (if any)
    func playlistForSong(_ songId: String) -> String? {
        for (playlist, songs) in playlists {
            if songs.contains(songId) {
                return playlist
            }
        }
        return nil
    }
    
    /// Gets all available playlists
    func getPlaylists() -> [String] {
        return Array(playlists.keys).sorted()
    }
    
    /// Saves playlists to persistent storage
    private func savePlaylists() {
        print("💾 Saving playlists configuration...")
        do {
            let data = try JSONEncoder().encode(playlists)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("✅ Playlists saved successfully")
        } catch {
            print("❌ Failed to save playlists: \(error.localizedDescription)")
        }
    }
    
    /// Loads playlists from persistent storage
    private func loadPlaylists() {
        print("📂 Loading playlists configuration...")
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            print("ℹ️ No saved playlists found")
            return
        }
        
        do {
            playlists = try JSONDecoder().decode([String: Set<String>].self, from: data)
            print("✅ Playlists loaded successfully")
        } catch {
            print("❌ Failed to load playlists, clearing invalid data: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: storageKey)
            playlists = [:]
        }
    }
    
    /// Validates consistency with music library
    @objc private func validateConsistency() {
        print("🔍 Validating playlist consistency...")
        
        // Remove references to songs that no longer exist
        let validSongIds = Set(musicLibrary.songs.map { $0.id })
        for (playlist, songs) in playlists {
            let validSongs = songs.intersection(validSongIds)
            if validSongs.count != songs.count {
                print("⚠️ Removing invalid songs from playlist: \(playlist)")
                playlists[playlist] = validSongs
            }
        }
        
        // Remove empty playlists
        playlists = playlists.filter { !$0.value.isEmpty }
        
        savePlaylists()
        print("✅ Playlist consistency check complete")
    }
    
    /// Clears all playlists
    func clearPlaylists() {
        print("🧹 Clearing all playlists...")
        playlists.removeAll()
        savePlaylists()
        print("✅ All playlists cleared")
    }
} 
