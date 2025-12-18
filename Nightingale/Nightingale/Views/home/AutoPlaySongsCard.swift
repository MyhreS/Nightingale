import SwiftUI

struct AutoPlayToggle: View {
    @Binding var isEnabled: Bool

    var body: some View {
        HStack {
            Image(systemName: "repeat")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isEnabled ? .white : .secondary)
            
            Text("Auto-play")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(isEnabled ? .white : .secondary)
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(Color(red: 0.3, green: 0.7, blue: 0.4))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
