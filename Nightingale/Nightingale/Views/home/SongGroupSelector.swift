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
                .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .frame(minHeight: 44)
                .background(
                    isSelected ? 
                        AnyShapeStyle(Color.orange.opacity(0.25)) : 
                        AnyShapeStyle(.thickMaterial),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(isSelected ? Color.orange.opacity(0.6) : Color.clear, lineWidth: 1.5)
                )
                .foregroundStyle(isSelected ? .orange : .white)
        }
        .buttonStyle(.plain)
    }
}
