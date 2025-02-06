import SwiftUI

struct Toolbar: View {
    @State private var showSettings = false

    var body: some View {
        HStack {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showSettings.toggle()
                }
            }) {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.primary)
            }
            .fullScreenCover(isPresented: $showSettings) {
                Settings(showSettings: $showSettings)
            }

            Text("Nightingale")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 5)

            Spacer()
        }
    }
}


