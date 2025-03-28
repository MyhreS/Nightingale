import SwiftUI

struct BottomDrawer: View {
    var body: some View {
        HStack {
            Spacer()
            Image(systemName: "house.fill")
                .font(.title2)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.white)
            Spacer()
        }
        .frame(height: 60)
    }
}
