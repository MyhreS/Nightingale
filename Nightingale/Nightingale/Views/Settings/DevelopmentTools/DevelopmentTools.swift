import SwiftUI

struct DevelopmentToolsView: View {
    @Binding var clearFeedback: Bool
    @Binding var resetFeedback: Bool
    let resetPlayedStatus: () -> Void

    var body: some View {
        CustomCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Development Tools")
                    .font(.headline)

                ClearLibraryButton(clearFeedback: $clearFeedback)
                ResetPlayedStatusButton(resetFeedback: $resetFeedback, resetPlayedStatus: resetPlayedStatus)

                Text("Use this when rebuilding the app to clear stale configuration")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}
