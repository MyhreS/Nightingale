import SwiftUI

struct MoreButton: View {
    @State private var showManageSheet = false
    
    var body: some View {
        Button(action: { showManageSheet = true }) {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
        .sheet(isPresented: $showManageSheet) {
            ManageSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}


