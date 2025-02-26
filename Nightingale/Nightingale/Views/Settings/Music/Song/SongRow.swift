import SwiftUI

struct SongRow: View {
    let song: MusicFile
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading) {
                    Text(song.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Starts at: \(String(format: "%.1f", song.startTime))s")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
        .buttonStyle(.plain)
    }
} 