import SwiftUI

struct AddButton: View {
    @State private var showAddSheet = false
    @StateObject private var fileImporterHelper = FileImporterHelper()

    var body: some View {
        Button(action: { showAddSheet = true }) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title3)
        }
        .sheet(isPresented: $showAddSheet) {
            AddSheet(fileImporterHelper: fileImporterHelper)
                .presentationDetents([.height(150)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: fileImporterHelper.status) { _, newStatus in
            if newStatus == .success || newStatus == .failure {
                showAddSheet = false
            }
        }
    }

    private var iconName: String {
        switch fileImporterHelper.status {
        case .success:
            return "checkmark.circle.fill"
        case .failure:
            return "xmark.circle.fill"
        default:
            return "plus.circle.fill"
        }
    }

    private var iconColor: Color {
        switch fileImporterHelper.status {
        case .success:
            return .green
        case .failure:
            return .red
        default:
            return .blue
        }
    }
}
