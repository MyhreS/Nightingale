import SwiftUI
import SoundCloud

struct SettingsPage: View {
    let sc: SoundCloud
    let user: User

    var isAdmin: Bool {
        user.id == "soundcloud:users:1531282276"
    }
    
    var body: some View {
        PageLayout(title: "Settings") {
            VStack(alignment: .leading, spacing: 20) {
                userHeader

                if isAdmin {
                    AdminSettings(onPrintLikedTracks: printUserLikedTracksIds)
                }

                Spacer()
            }
        }
    }

    var userHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 52, height: 52)

                Text(initials)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(displayName)
                    .font(.headline)
                Text("@\(user.username)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
        )
    }

    var displayName: String {
        user.firstName ?? user.username
    }

    var initials: String {
        let base = user.firstName ?? user.username
        let first = base.first.map { String($0).uppercased() } ?? ""
        return first
    }
    
    func printUserLikedTracksIds() {
        Task {
            do {
                let res = try await sc.likedTracks()
                print("Liked tracks")
                for track in res.items {
                    print("Track name: \(track.title)")
                    print("Track ID: \(track.id)")
                    print("Track artwork URL: \(track.artworkUrl ?? "")")
                    print("Track duration: \(track.duration)")
                    print("Track playback URL: \(track.playbackUrl ?? "")")
                    print("Track permalink: \(track.permalinkUrl)")
                    print("Track user permalinkURL: \(track.user.permalinkUrl)")
                    print("Tracks user name: \(track.user.username)")
                    print("-")
                }
            } catch {
                print("❌ \(error)")
            }
        }
        
    }

    struct AdminSettings: View {
        let onPrintLikedTracks: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Admin")
                    .font(.headline)

                HapticButton(action: onPrintLikedTracks) {
                    HStack(spacing: 8) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Print most liked tracks IDs")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemBackground))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
