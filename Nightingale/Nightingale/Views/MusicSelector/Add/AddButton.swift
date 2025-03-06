import SwiftUI

struct AddButton: View {
    @State private var showAddSheet = false
    @StateObject private var fileImporterHelper = FileImporterHelper()

    var body: some View {
        Button(action: { showAddSheet = true }) {
            Image(systemName: fileImporterHelper.isSuccess ? "checkmark.circle.fill" : "plus.circle.fill")
                .foregroundColor(fileImporterHelper.isSuccess ? .green : .blue)
                .font(.title3)
        }
        .sheet(isPresented: $showAddSheet) {
            AddSheet(fileImporterHelper: fileImporterHelper)
                .presentationDetents([.height(150)])
                .presentationDragIndicator(.visible)
        }
    }
}
