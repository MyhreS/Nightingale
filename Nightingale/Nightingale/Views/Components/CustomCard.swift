import SwiftUI

struct CustomCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
    }
}

#Preview {
    CustomCard {
        Text("Example Card")
            .padding()
    }
    .padding()
    .background(Color.blue.opacity(0.1))
} 