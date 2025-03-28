import SwiftUI

struct ClearLibraryButton: View {
    @State private var success = false

    var body: some View {
        Button(action: {
            MusicLibrary.shared.removeAllMusic()
            withAnimation {
                success = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    success = false
                }
            }
        }) {
            HStack {
                if success {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Library Cleared!")
                } else {
                    Image(systemName: "trash")
                    Text("Clear Music Library")
                }
            }
            .foregroundColor(success ? .green : .red)
            .padding()
            .background(success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
        }
    }
}
