import SwiftUI

struct Toolbar: View {
    var body: some View {
        HStack {
            Button(action: {
                print("Settings tapped")
            }) {
                Image(systemName: "gearshape.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.primary)
            }

            Text("Nightingale")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.leading, 5)

            Spacer()
        }
    }
}
