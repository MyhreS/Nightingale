import SwiftUI

struct RemoveButton: View {
    @State var showRemoveSheet: Bool = false
    @State var successfullyRemoved: Bool = false
    
    var body: some View {
        Button(action: {showRemoveSheet = true}) {
            Image(systemName: getIcon)
                .foregroundColor(.red)
                .font(.title3)
        }
        .sheet(isPresented: $showRemoveSheet) {
            RemoveSheet(successfullyRemoved: $successfullyRemoved)
                .presentationDetents([.fraction(0.2)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: successfullyRemoved) { _, newStatus in
            if newStatus {
                showRemoveSheet = false
            }
            
        }
    }
    
    private var getIcon : String {
        if (successfullyRemoved) {
            return "checkmark.circle.fill"
        }
        return "minus.circle.fill"
    }
    
               
}
