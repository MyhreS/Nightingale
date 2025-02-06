import SwiftUI

struct SettingsToolbar: View {
    @Binding var showSettings: Bool

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    showSettings = false // Close settings
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.primary)
            }

            Text("Settings")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 5)

            Spacer()
        }
    }
}
