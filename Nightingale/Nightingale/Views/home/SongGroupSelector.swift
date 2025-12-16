import SwiftUI

struct SongGroupSelector: View {
    let groups: [SongGroup]
    @Binding var selectedGroup: SongGroup
    let isLoading: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if isLoading {
                    ForEach(0..<4, id: \.self) { _ in
                        GroupChipSkeleton()
                    }
                } else {
                    ForEach(groups, id: \.self) { group in
                        GroupChip(
                            title: group.displayName,
                            isSelected: group == selectedGroup
                        ) {
                            selectedGroup = group
                        }
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
                        AnyShapeStyle(Color.white) : 
                        AnyShapeStyle(Color(white: 0.12)),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : Color(white: 0.2), lineWidth: 1)
                )
                .foregroundStyle(isSelected ? .black : Color(white: 0.7))
        }
        .buttonStyle(.plain)
    }
}

struct GroupChipSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(white: 0.12))
            .frame(width: 80, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color(white: 0.2), lineWidth: 1)
            )
            .shimmer()
    }
}
