import SwiftUI

struct Settings: View {
    @Binding var showSettings: Bool

    var body: some View {
        VStack(spacing: 0) { // Use spacing to remove gaps between sections
            // Top bar
            HStack {
                Button(action: {
                    withAnimation {
                        showSettings = false // Dismiss settings
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.gray)
                        .padding(.leading) // Add left padding
                }

                Spacer()

                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .center) // Center-align text

                Spacer().frame(width: 48) // Match the size of the xmark button
            }
            .padding([.top, .horizontal]) // Add top padding for safe area
            .background(Color.white) // Background for top bar

            Divider() // Separate the top bar visually

            // Content Section
            ScrollView { // Scrollable area for large settings
                VStack(alignment: .leading, spacing: 20) {
                    // Add Music Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Add Music")
                            .font(.headline)
                            .fontWeight(.bold)

                        Button(action: {
                            // Action to add music
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.blue)

                                Text("Add New Music")
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                        }
                    }

                    // Additional sections can go here
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Other Settings")
                            .font(.headline)
                            .fontWeight(.bold)

                        Text("This is where you can add additional settings or information.")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                }
                .padding() // Add padding around content
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea()) // Full screen white background
    }
}
