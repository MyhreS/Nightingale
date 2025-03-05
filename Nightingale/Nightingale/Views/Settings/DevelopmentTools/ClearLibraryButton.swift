import SwiftUI


struct ClearLibraryButton: View {
    @Binding var clearFeedback: Bool

    var body: some View {
        Button(action: {
            MusicLibrary.shared.removeAllMusic()
            withAnimation {
                clearFeedback = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    clearFeedback = false
                }
            }
        }) {
            HStack {
                if clearFeedback {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Library Cleared!")
                } else {
                    Image(systemName: "trash")
                    Text("Clear Music Library")
                }
            }
            .foregroundColor(clearFeedback ? .green : .red)
            .padding()
            .background(clearFeedback ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
        }
    }
}
