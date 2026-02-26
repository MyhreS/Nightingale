import SwiftUI
import SoundCloud

struct SettingsPage: View {
    let sc: SoundCloud
    let scUser: User?
    let hasFirebaseAccess: Bool
    let onConnectSoundCloud: () -> Void
    let onDisconnectSoundCloud: () -> Void

    @EnvironmentObject var firebaseAPI: FirebaseAPI
    @AppStorage("userEmail") private var email = ""
    @AppStorage("isAutoPlayEnabled") private var isAutoPlayEnabled = true
    @State private var isEditingEmail = false
    @State private var emailDraft = ""
    @FocusState private var emailFieldFocused: Bool

    private var scIsConnected: Bool { scUser != nil }

    var body: some View {
        PageLayout(title: "Settings") {
            VStack(alignment: .leading, spacing: 20) {
                if firebaseAPI.soundcloudLoginEnabled {
                    if hasFirebaseAccess {
                        soundCloudDisabledCard
                    } else {
                        soundCloudCard
                    }
                }

                if firebaseAPI.emailLoginEnabled && !scIsConnected {
                    emailCard
                }

                autoPlayToggle

                Spacer()
            }
        }
    }

    private var emailDisabledCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(white: 0.3))

            Text("Disconnect SoundCloud to use email-based access")
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.3))

            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Color(white: 0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(white: 0.12), lineWidth: 1)
        )
    }

    private var soundCloudDisabledCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "cloud.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(white: 0.4))

            VStack(alignment: .leading, spacing: 4) {
                Text("SoundCloud")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color(white: 0.4))
                Text("You're using email-based access. SoundCloud is disabled.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(white: 0.35))
            }

            Spacer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(white: 0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    @ViewBuilder
    private var emailCard: some View {
        if isEditingEmail {
            HStack(spacing: 10) {
                TextField("", text: $emailDraft)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .submitLabel(.done)
                    .focused($emailFieldFocused)
                    .onSubmit { saveEmail() }

                HapticButton(action: saveEmail) {
                    Text("Save")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.white, in: Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(white: 0.2), lineWidth: 1)
            )
            .onAppear { emailFieldFocused = true }
        } else if email.isEmpty {
            HapticButton(action: beginEditingEmail) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.4))
                    Text("Email")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color(white: 0.4))

                    Spacer()

                    Text("Add")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color(white: 0.5))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color(white: 0.15), in: Capsule())
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(white: 0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color(white: 0.15), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        } else {
            let verified = hasFirebaseAccess
            let accentColor = verified ? Color(red: 0.3, green: 0.7, blue: 0.4) : Color(white: 0.5)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: verified ? "checkmark.seal.fill" : "envelope.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(accentColor)

                    Text(email)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(verified ? .white : Color(white: 0.7))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    HapticButton(action: beginEditingEmail) {
                        Text("Change")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color(white: 0.5))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color(white: 0.15), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    HapticButton(action: clearEmail) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(white: 0.3))
                    }
                    .buttonStyle(.plain)
                }

            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(
                (verified ? accentColor.opacity(0.06) : Color(white: 0.06)),
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(verified ? accentColor.opacity(0.4) : Color(white: 0.15), lineWidth: 1)
            )
        }
    }

    private var autoPlayToggle: some View {
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

    @ViewBuilder
    private var soundCloudCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(red: 1.0, green: 0.33, blue: 0.0))

                Text("SoundCloud")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                if scUser == nil {
                    Text("Get ready-to-play songs")
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.5))
                }
            }

            if let scUser {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(red: 0.3, green: 0.7, blue: 0.4))
                    Text("@\(scUser.username)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white)
                }

                HapticButton(action: onDisconnectSoundCloud) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Log out of Soundcloud")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(Color(red: 0.9, green: 0.3, blue: 0.3))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color(red: 0.9, green: 0.3, blue: 0.3).opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            } else {
                SoundCloudInfoDropdown()

                HapticButton(action: onConnectSoundCloud) {
                    HStack(spacing: 8) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Connect")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 1.0, green: 0.33, blue: 0.0).opacity(0.15), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color(red: 1.0, green: 0.33, blue: 0.0).opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color(red: 1.0, green: 0.33, blue: 0.0).opacity(0.5), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    private func beginEditingEmail() {
        emailDraft = email
        isEditingEmail = true
    }

    private func saveEmail() {
        let trimmed = emailDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        email = trimmed
        isEditingEmail = false
    }

    private func clearEmail() {
        email = ""
        emailDraft = ""
        isEditingEmail = false
    }
}
