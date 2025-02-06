import SwiftUI

struct OtherSettings: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Other Settings")
                .font(.headline)
                .fontWeight(.bold)

            Text("Additional settings or information can be added here.")
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}
