import SwiftUI
import UniformTypeIdentifiers

struct RemoveMusicButton: View {
    @State private var isSuccess = false
    
    var body: some View {
        Button(action: {
            isSuccess.toggle()
        }) {
            HStack {
                Image(systemName: isSuccess ? "checkmark.circle.fill" : "minus.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isSuccess ? Color.red.darker() : .red)
                
                Text(isSuccess ? "Removed!" : "Remove")
                    .font(.body)
                    .foregroundColor(isSuccess ? Color.red.darker() : .red)
            }
            .frame(maxWidth: .infinity) // Make both buttons equal width
            .padding()
            .background(isSuccess ? Color.red.opacity(0.3) : Color.red.opacity(0.1))
            .cornerRadius(10)
        }
    }
}
