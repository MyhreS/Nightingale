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
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 56, height: 56)

                Text(initials)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.orange)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(.system(size: 17, weight: .semibold))
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.tertiarySystemFill))
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
                    .font(.system(size: 17, weight: .semibold))

                HapticButton(action: onPrintLikedTracks) {
                    HStack(spacing: 12) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(.orange)
                        Text("Print most liked tracks IDs")
                            .font(.system(size: 15, weight: .medium))
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(.tertiarySystemFill))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
