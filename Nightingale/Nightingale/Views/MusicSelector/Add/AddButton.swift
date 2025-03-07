import SwiftUI

struct AddButton: View {
    @State private var showAddSheet = false
    @StateObject private var fileImporterHelper = FileImporterHelper()
    @State private var successfullyAddedPlaylist = false

    var body: some View {
        Button(action: { showAddSheet = true }) {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
                .font(.title3)
        }
        .sheet(isPresented: $showAddSheet) {
            AddSheet(fileImporterHelper: fileImporterHelper, successfullyAddedPlaylist: $successfullyAddedPlaylist)
                .presentationDetents([.fraction(0.2)])
                .presentationDragIndicator(.visible)
        }
        .onChange(of: fileImporterHelper.status) { _, newStatus in
            if newStatus == .success || newStatus == .failure {
                showAddSheet = false
            }
        }
        .onChange(of: successfullyAddedPlaylist) { _, newStatus in
            if newStatus {
                showAddSheet = false
            }
        }
    }

    private var iconName: String {
        if successfullyAddedPlaylist {
            return "checkmark.circle.fill"
        }
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
        if successfullyAddedPlaylist {
            return .green
        }
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
