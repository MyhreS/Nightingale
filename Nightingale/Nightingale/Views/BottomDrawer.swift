import SwiftUI

struct BottomDrawer: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            Spacer()
            Button(action: {
                selectedTab = .home
            }) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(selectedTab == .home ? .white : .gray)
            }
            Spacer()
            Button(action: {
                selectedTab = .settings
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(selectedTab == .settings ? .white : .gray)
            }
            Spacer()
        }
        .frame(height: 60)
    }
}
