import SwiftUI

struct SongOptionsPopup: View {
    let song: Song
    let onClose: () -> Void
    let onDelete: (Song) -> Void
    let onUpdateStartTime: (Song, Int) -> Void
    let onEdit: (Song, String, String) -> Void

    enum Page { case menu, details, startTime, edit }

    @State private var currentPage: Page = .menu
    @State private var editedStartSeconds: Int = 0
    @State private var editedName: String = ""
    @State private var editedArtist: String = ""
    @State private var showDeleteConfirmation = false

    private var isLocal: Bool { song.streamingSource == .local }

    private var headerArtist: String {
        let artist = song.originalSongArtistName.isEmpty ? song.artistName : song.originalSongArtistName
        return artist.trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture { onClose() }

            popupContent
                .padding(20)
                .frame(maxWidth: 300)
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(white: 0.2), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
                .padding(.horizontal, 20)
        }
        .onAppear {
        editedStartSeconds = song.startSeconds
        editedName = song.name
        editedArtist = song.artistName
    }
    }

    @ViewBuilder
    private var popupContent: some View {
        switch currentPage {
        case .menu:
            menuPage
        case .details:
            detailsPage
        case .startTime:
            startTimePage
        case .edit:
            editPage
        }
    }

    private var menuPage: some View {
        VStack(spacing: 12) {
            songHeader

            VStack(spacing: 0) {
                menuRow(icon: "info.circle", title: "Song Details", enabled: true) {
                    withAnimation(.easeInOut(duration: 0.2)) { currentPage = .details }
                }

                Divider().background(Color(white: 0.2))

                editMenuRow

                Divider().background(Color(white: 0.2))

                startTimeMenuRow

                Divider().background(Color(white: 0.2))

                deleteMenuRow
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    @ViewBuilder
    private var editMenuRow: some View {
        if isLocal {
            menuRow(icon: "pencil", title: "Edit Song", enabled: true) {
                withAnimation(.easeInOut(duration: 0.2)) { currentPage = .edit }
            }
        } else {
            lockedRow(icon: "pencil", title: "Edit Song", reason: "Server songs can't be edited")
        }
    }

    @ViewBuilder
    private var startTimeMenuRow: some View {
        if isLocal {
            menuRow(icon: "clock", title: "Adjust Start Time", enabled: true) {
                withAnimation(.easeInOut(duration: 0.2)) { currentPage = .startTime }
            }
        } else {
            lockedRow(icon: "clock", title: "Start Time", reason: "Defined on the server")
        }
    }

    @ViewBuilder
    private var deleteMenuRow: some View {
        if isLocal {
            menuRow(
                icon: "trash",
                title: "Delete Song",
                enabled: true,
                destructive: true
            ) {
                showDeleteConfirmation = true
            }
            .alert("Delete Song", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete(song)
                    onClose()
                }
            } message: {
                Text("This will permanently remove \"\(song.name)\" from your device.")
            }
        } else {
            lockedRow(icon: "trash", title: "Delete Song", reason: "Server songs can't be deleted from the app")
        }
    }

    private var detailsPage: some View {
        VStack(spacing: 16) {
            backButton

            if let url = URL(string: song.artworkURL), !song.artworkURL.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.15))
                }
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            }

            VStack(spacing: 8) {
                if !song.name.isEmpty {
                    Text(song.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }

                if !headerArtist.isEmpty {
                    Text("by \(headerArtist)")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(white: 0.6))
                }

                if song.duration > 0 {
                    Text(formattedDuration(ms: song.duration))
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.5))
                        .padding(.top, 2)
                }

                Text(sourceLabel)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.4))
                    .padding(.top, 4)
            }
            .padding(.horizontal, 12)

            VStack(spacing: 12) {
                if !song.linkToSong.isEmpty, let songUrl = URL(string: song.linkToSong) {
                    linkRow(destination: songUrl, title: "Open song on SoundCloud", icon: "music.note")
                }

                if !song.linkToArtist.isEmpty, let artistUrl = URL(string: song.linkToArtist) {
                    linkRow(destination: artistUrl, title: "Open artist on SoundCloud", icon: "person.fill")
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var startTimePage: some View {
        VStack(spacing: 20) {
            backButton

            Text("Adjust Start Time")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Text("Set where the song begins playing")
                .font(.system(size: 14))
                .foregroundStyle(Color(white: 0.6))
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text(formattedTime(seconds: editedStartSeconds))
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)

                HStack(spacing: 20) {
                    stepButton(systemName: "minus.circle.fill") {
                        editedStartSeconds = max(0, editedStartSeconds - 1)
                    }

                    stepButton(systemName: "minus.circle") {
                        editedStartSeconds = max(0, editedStartSeconds - 5)
                    }

                    stepButton(systemName: "plus.circle") {
                        editedStartSeconds += 5
                    }

                    stepButton(systemName: "plus.circle.fill") {
                        editedStartSeconds += 1
                    }
                }
            }
            .padding(16)
            .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color(white: 0.2), lineWidth: 1)
            )

            HapticButton(action: {
                onUpdateStartTime(song, editedStartSeconds)
                onClose()
            }) {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
    }

    private var editPage: some View {
        VStack(spacing: 20) {
            backButton

            Text("Edit Song")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 6) {
                Text("Name")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(white: 0.5))

                TextField("Song name", text: $editedName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(white: 0.2), lineWidth: 1)
                    )
                    .autocorrectionDisabled()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Artist")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(white: 0.5))

                TextField("Artist name", text: $editedArtist)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
                    .padding(14)
                    .background(Color(white: 0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color(white: 0.2), lineWidth: 1)
                    )
                    .autocorrectionDisabled()
            }

            HapticButton(action: saveEdit) {
                Text("Save")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background(
                        editedName.trimmingCharacters(in: .whitespaces).isEmpty
                            ? Color(white: 0.3)
                            : Color.white,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                    )
            }
            .buttonStyle(.plain)
            .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func saveEdit() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedArtist = editedArtist.trimmingCharacters(in: .whitespacesAndNewlines)
        onEdit(song, trimmedName, trimmedArtist)
        onClose()
    }

    private var songHeader: some View {
        HStack(spacing: 10) {
            if let url = URL(string: song.originalArtWorkUrl.isEmpty ? song.artworkURL : song.originalArtWorkUrl),
               !song.artworkURL.isEmpty || !song.originalArtWorkUrl.isEmpty {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8).fill(Color(white: 0.15))
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(white: 0.15))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(white: 0.4))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(song.originalSongName.isEmpty ? song.name : song.originalSongName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if !headerArtist.isEmpty {
                    Text(headerArtist)
                        .font(.system(size: 13))
                        .foregroundStyle(Color(white: 0.6))
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(.bottom, 4)
    }

    private var backButton: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { currentPage = .menu }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Back")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundStyle(Color(white: 0.6))
            }
            Spacer()
        }
    }

    private var sourceLabel: String {
        switch song.streamingSource {
        case .soundcloud: return "Source: SoundCloud"
        case .firebase: return "Source: Server"
        case .local: return "Source: Local file"
        }
    }

    private func menuRow(
        icon: String,
        title: String,
        enabled: Bool,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .frame(width: 24)
                    .foregroundStyle(destructive ? Color(red: 0.9, green: 0.3, blue: 0.3) : .white)
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(destructive ? Color(red: 0.9, green: 0.3, blue: 0.3) : .white)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(white: 0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(white: 0.12))
        }
        .disabled(!enabled)
    }

    private func lockedRow(icon: String, title: String, reason: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .frame(width: 24)
                .foregroundStyle(Color(white: 0.3))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(white: 0.3))
                Text(reason)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(white: 0.25))
            }
            Spacer()
            Image(systemName: "lock.fill")
                .font(.system(size: 12))
                .foregroundStyle(Color(white: 0.25))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(white: 0.12))
    }

    private func linkRow(destination: URL, title: String, icon: String) -> some View {
        Link(destination: destination) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.system(size: 15, weight: .medium))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
            .background(Color(white: 0.12))
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(white: 0.25), lineWidth: 1)
            )
        }
    }

    private func stepButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 28))
                .foregroundStyle(.white)
        }
    }

    private func formattedDuration(ms: Int) -> String {
        let totalSeconds = ms / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func formattedTime(seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
