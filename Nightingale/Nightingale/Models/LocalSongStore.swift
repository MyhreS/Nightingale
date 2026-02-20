import Foundation
import AVFoundation

@MainActor
final class LocalSongStore {
    static let shared = LocalSongStore()

    private let baseURL: URL
    private let metadataURL: URL

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        baseURL = docs.appendingPathComponent("local-songs", isDirectory: true)
        metadataURL = baseURL.appendingPathComponent("metadata.json")
        try? FileManager.default.createDirectory(at: baseURL, withIntermediateDirectories: true)
    }

    func allSongs() -> [Song] {
        guard let data = try? Data(contentsOf: metadataURL),
              let songs = try? JSONDecoder().decode([Song].self, from: data) else {
            return []
        }
        return songs
    }

    private func saveSongs(_ songs: [Song]) {
        guard let data = try? JSONEncoder().encode(songs) else { return }
        try? data.write(to: metadataURL, options: .atomic)
    }

    func addSong(from sourceURL: URL, group: SongGroup) async -> Song? {
        let songId = UUID().uuidString
        let ext = sourceURL.pathExtension.isEmpty ? "mp3" : sourceURL.pathExtension
        let fileName = "\(songId).\(ext)"
        let destinationURL = baseURL.appendingPathComponent(fileName)

        let accessing = sourceURL.startAccessingSecurityScopedResource()
        defer { if accessing { sourceURL.stopAccessingSecurityScopedResource() } }

        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            print("Failed to copy audio file: \(error)")
            return nil
        }

        let metadata = await extractMetadata(from: destinationURL)

        let fallbackName = sourceURL.deletingPathExtension().lastPathComponent
        let song = Song(
            songId: songId,
            name: metadata.title ?? fallbackName,
            artistName: metadata.artist ?? "Unknown Artist",
            originalSongName: metadata.title ?? fallbackName,
            originalSongArtistName: metadata.artist ?? "Unknown Artist",
            originalArtWorkUrl: "",
            artworkURL: "",
            duration: metadata.durationMs,
            playbackUrl: fileName,
            linkToSong: "",
            linkToArtist: "",
            group: group,
            startSeconds: 0,
            streamingSource: .local
        )

        var songs = allSongs()
        songs.append(song)
        saveSongs(songs)

        return song
    }

    func deleteSong(_ song: Song) {
        guard song.streamingSource == .local else { return }

        let fileURL = baseURL.appendingPathComponent(song.playbackUrl)
        try? FileManager.default.removeItem(at: fileURL)

        var songs = allSongs()
        songs.removeAll { $0.songId == song.songId }
        saveSongs(songs)
    }

    func updateStartTime(songId: String, startSeconds: Int) {
        var songs = allSongs()
        if let index = songs.firstIndex(where: { $0.songId == songId }) {
            songs[index].startSeconds = startSeconds
            saveSongs(songs)
        }
    }

    func fileURL(for song: Song) -> URL {
        baseURL.appendingPathComponent(song.playbackUrl)
    }

    private struct AudioMetadata {
        var title: String?
        var artist: String?
        var durationMs: Int
    }

    private func extractMetadata(from url: URL) async -> AudioMetadata {
        let asset = AVURLAsset(url: url)

        var title: String?
        var artist: String?
        var durationMs: Int = 0

        do {
            let duration = try await asset.load(.duration)
            durationMs = Int(CMTimeGetSeconds(duration) * 1000)
        } catch { }

        do {
            let metadata = try await asset.load(.commonMetadata)
            for item in metadata {
                guard let key = item.commonKey else { continue }
                switch key {
                case .commonKeyTitle:
                    title = try? await item.load(.stringValue)
                case .commonKeyArtist:
                    artist = try? await item.load(.stringValue)
                default:
                    break
                }
            }
        } catch { }

        return AudioMetadata(title: title, artist: artist, durationMs: durationMs)
    }
}
