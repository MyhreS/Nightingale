import SwiftUI

struct AddSongRow: View {
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(white: 0.15))
                    .frame(width: 52, height: 52)

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color(white: 0.5))
            }

            Text("Add Song")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(white: 0.5))

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(minHeight: 68)
        .background(
            Color(white: 0.08),
            in: RoundedRectangle(cornerRadius: 14)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color(white: 0.2), style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
        )
        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}
