import SwiftUI

struct Settings: View {
    @Binding var showSettings: Bool
    @State private var clearFeedback = false
    @State private var resetFeedback = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Music()
                        .frame(maxWidth: .infinity)
                    
                    // Development Tools Section
                    CustomCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Development Tools")
                                .font(.headline)
                            
                            Button(action: {
                                MusicLibrary.shared.clearConfiguration()
                                withAnimation {
                                    clearFeedback = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        clearFeedback = false
                                    }
                                }
                            }) {
                                HStack {
                                    if clearFeedback {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Library Cleared!")
                                    } else {
                                        Image(systemName: "trash")
                                        Text("Clear Music Library")
                                    }
                                }
                                .foregroundColor(clearFeedback ? .green : .red)
                                .padding()
                                .background(clearFeedback ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                MusicLibrary.shared.resetPlayedStatus()
                                withAnimation {
                                    resetFeedback = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        resetFeedback = false
                                    }
                                }
                            }) {
                                HStack {
                                    if resetFeedback {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Status Reset!")
                                    } else {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Reset Played Status")
                                    }
                                }
                                .foregroundColor(resetFeedback ? .green : .blue)
                                .padding()
                                .background(resetFeedback ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                            
                            Text("Use this when rebuilding the app to clear stale configuration")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
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
