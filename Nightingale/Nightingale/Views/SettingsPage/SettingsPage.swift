import SwiftUI

struct SettingsPage: View {
    @State private var clearFeedback = false
    @State private var resetFeedback = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Settings")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                SettingsRow(title: "Clear Music Library") {
                    ClearLibraryButton()
                }

                SettingsRow(title: "Reset Played Status") {
                    ResetPlayedStatusButton()
                }

                Text("Use this when rebuilding the app to clear stale configuration.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}
