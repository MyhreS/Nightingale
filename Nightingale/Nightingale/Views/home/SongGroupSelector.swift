import SwiftUI

struct SongGroupSelector: View {
    let groups: [SongGroup]
    @Binding var selectedGroup: SongGroup

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(groups) { group in
                    GroupChip(
                        title: group.displayName,
                        isSelected: group == selectedGroup
                    ) {
                        selectedGroup = group
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 2)
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
                .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isSelected ? Color.orange.opacity(0.2) : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isSelected ? .orange : .primary)
        }
        .buttonStyle(.plain)
    }
}
