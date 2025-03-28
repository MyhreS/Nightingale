import SwiftUI

struct ResetPlayedStatusButton: View {
    @Binding var resetFeedback: Bool
    let resetPlayedStatus: () -> Void

    var body: some View {
        Button(action: {
            resetPlayedStatus()
            withAnimation {
                resetFeedback = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    resetFeedback = false
                }
            }
        }) {
            HStack {
                if resetFeedback {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Status Reset!")
                } else {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Played Status")
                }
            }
            .foregroundColor(resetFeedback ? .green : .blue)
            .padding()
            .background(resetFeedback ? Color.green.opacity(0.1) : Color.blue.opacity(0.1))
            .cornerRadius(10)
            .frame(maxWidth: .infinity)
        }
    }
}
