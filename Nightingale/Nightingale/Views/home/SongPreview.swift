import SwiftUI


struct SongPreview: View {
    let song: PredefinedSong
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            VStack(spacing: 20) {
                    AsyncImage(url: URL(string: song.artworkURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.orange.opacity(0.2))
                    }
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    VStack(spacing: 6) {
                        Text(song.name)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("by \(song.artistName)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text(formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        if let songUrl = URL(string: song.linkToSong) {
                            Link(destination: songUrl) {
                                Label("Open song on SoundCloud", systemImage: "music.note")
                                    .font(.subheadline)
                            }
                        }
                        
                        if let artistUrl = URL(string: song.linkToArtist) {
                            Link(destination: artistUrl) {
                                Label("Open artist on SoundCloud", systemImage: "person.fill")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .frame(maxWidth: 320)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal, 16)
        }
    }
    
    var formattedDuration: String {
        let totalSeconds = song.duration / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func onPlay() {
        print("Not implemented: \(song.name) (\(song.id))")
    }
}
