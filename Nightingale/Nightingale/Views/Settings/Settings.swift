import SwiftUI

struct Settings: View {
    @Binding var showSettings: Bool
    @State private var clearFeedback = false
    @State private var resetFeedback = false
    
    private func resetPlayedStatus() {
        let musicFiles = MusicLibrary.shared.getMusicFiles()

        musicFiles.forEach { musicFile in
            var editedMusicFile = musicFile
            editedMusicFile.played = false
            MusicLibrary.shared.editMusicFile(editedMusicFile)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Music()
                        .frame(maxWidth: .infinity)

                    DevelopmentToolsView(
                        clearFeedback: $clearFeedback,
                        resetFeedback: $resetFeedback,
                        resetPlayedStatus: resetPlayedStatus
                    )
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        SettingsToolbar(showSettings: $showSettings)
                    }
                }
            }
            .background(Color.blue.opacity(0.1))
        }
    }
}
