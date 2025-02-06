import SwiftUI

struct Settings: View {
    @Binding var showSettings: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    AddMusic()
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                    
                    OtherSettings()
                        .frame(maxWidth: .infinity, maxHeight: 150)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(20)
                        .shadow(radius: 10)
                }
                .padding()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        SettingsToolbar(showSettings: $showSettings)
                    }
                }
            }
        }
    }
}
