import SwiftUI

struct Settings: View {
    @Binding var showSettings: Bool

    var body: some View {
        VStack {
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
            

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white.ignoresSafeArea()) // Full screen white background
    }
}
