import SwiftUI

struct AddButton: View {
    @State private var showAddSheet = false
    
    var body: some View {
        Button(action: { showAddSheet = true }) {
            Image(systemName: "plus.circle.fill")
                .foregroundColor(.blue)
                .font(.title3)
        }
        .sheet(isPresented: $showAddSheet) {
            AddSheet()
            .presentationDetents([.height(150)])
            .presentationDragIndicator(.visible)
        }
        
    }
}
