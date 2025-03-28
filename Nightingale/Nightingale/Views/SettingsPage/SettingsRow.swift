import SwiftUI

struct SettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.white)
            Spacer()
            content()
        }
        .padding(.vertical, 8)
    }
}
