import SwiftUI

struct Settings: View {
    @Binding var showSettings: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Music()
                        .frame(maxWidth: .infinity)
                    
                    // Development Tools Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Development Tools")
                            .font(.headline)
                        
                        Button(action: {
                            MusicLibrary.shared.clearConfiguration()
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Music Library")
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(10)
                        }
                        
                        Text("Use this when rebuilding the app to clear stale configuration")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(15)
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
