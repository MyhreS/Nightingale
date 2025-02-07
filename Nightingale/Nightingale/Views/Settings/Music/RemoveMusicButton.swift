import SwiftUI
import UniformTypeIdentifiers

struct RemoveMusicButton: View {
    @State private var isShowingRemoveSheet = false
    
    var body: some View {
        Button(action: {
            isShowingRemoveSheet = true
        }) {
            HStack {
                Image(systemName: "minus.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.red.darker())
                
                Text("Remove")
                    .font(.body)
                    .foregroundColor(.red.darker())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
        }
        .sheet(isPresented: $isShowingRemoveSheet) {
            RemoveMusic(isPresented: $isShowingRemoveSheet)
        }
    }
}
