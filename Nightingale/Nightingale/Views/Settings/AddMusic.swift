import SwiftUI

struct AddMusic: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Add Music")
                .font(.headline)
                .fontWeight(.bold)
            
            Button(action: {
                // Action to add music
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(.blue)

                    Text("Add New Music")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
