import SwiftUI

struct SongGroupSelector: View {
    let groups: [SongGroup]
    @Binding var selectedGroup: SongGroup

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(groups) { group in
                    GroupChip(
                        title: group.displayName,
                        isSelected: group == selectedGroup
                    ) {
                        selectedGroup = group
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct GroupChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        HapticButton(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.orange.opacity(0.2) : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? .orange : .primary)
        }
        .buttonStyle(.plain)
    }
}
