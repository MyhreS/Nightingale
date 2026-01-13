import SwiftUI
import SoundCloud

struct SettingsPage: View {
    let sc: SoundCloud
    let user: User
    let onLogOut: () -> Void
    @AppStorage("isAutoPlayEnabled") private var isAutoPlayEnabled = true
    
    
    @State private var didCopy = false

    var isAdmin: Bool {
        user.id == "soundcloud:users:1531282276"
    }
    
    var body: some View {
        PageLayout(title: "Settings") {
            VStack(alignment: .leading, spacing: 20) {
                userHeader
                
                autoPlayToggle
                
                logOutButton

                if isAdmin {
                    AdminSettings(onPrintLikedTracks: printUserLikedTracksIds)
                }

                Spacer()
            }
        }
    }
    
    var logOutButton: some View {
        HapticButton(action: onLogOut) {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                Text("Log Out")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(white: 0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    var userHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(white: 0.15))
                    .frame(width: 56, height: 56)

                Text(initials)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                Text("@\(user.username)")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.6))
                Text(didCopy ? "Copied ✓" : "ID: \(userId)")
                    .font(.system(size: 14))
                    .foregroundStyle(Color(white: 0.6))
                    .onTapGesture {
                        UIPasteboard.general.string = userId
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        showCopiedFeedback()
                    }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(white: 0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
    
    var autoPlayToggle: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Auto play next song")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text("When a song finishes, automatically play the next song in the same group")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isAutoPlayEnabled)
                .labelsHidden()
                .tint(Color(red: 0.3, green: 0.7, blue: 0.4))
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(white: 0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            isAutoPlayEnabled.toggle()
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    var displayName: String {
        user.firstName ?? user.username
    }

    var initials: String {
        let base = user.firstName ?? user.username
        let first = base.first.map { String($0).uppercased() } ?? ""
        return first
    }
    
    var userId: String {
        return extractSoundCloudUserId(userId: user.id)
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
    
    private func showCopiedFeedback() {
        didCopy = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            didCopy = false
        }
    }

    struct AdminSettings: View {
        let onPrintLikedTracks: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                Text("Admin")
                    .font(.system(size: 17, weight: .semibold))

                // HapticButton(action: onPrintLikedTracks) {
                //     HStack(spacing: 12) {
                //         Image(systemName: "list.bullet.rectangle")
                //             .font(.system(size: 20, weight: .semibold))
                //             .foregroundStyle(.white)
                //         Text("Print most liked tracks IDs")
                //             .font(.system(size: 15, weight: .medium))
                //             .foregroundStyle(.white)
                        
                //         Spacer()
                //     }
                //     .padding(.horizontal, 16)
                //     .padding(.vertical, 14)
                //     .frame(maxWidth: .infinity, minHeight: 56)
                //     .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                //     .overlay(
                //         RoundedRectangle(cornerRadius: 14, style: .continuous)
                //             .strokeBorder(Color(white: 0.2), lineWidth: 1)
                //     )
                //     .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                // }
                // .buttonStyle(.plain)
            }
        }
    }
}
