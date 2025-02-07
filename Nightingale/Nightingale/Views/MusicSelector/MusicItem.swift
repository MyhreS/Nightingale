import SwiftUI

struct MusicItem: View {
    var file: URL
    
    var body: some View {
        Text(file.lastPathComponent)
            .font(.body)
            .listRowBackground(Color.blue.opacity(0))
    }
}
