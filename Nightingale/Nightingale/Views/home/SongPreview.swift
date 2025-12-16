import SwiftUI


struct SongPreview: View {
    let song: Song
    let onClose: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture {
                    onClose()
                }
            
            VStack(spacing: 16) {
                    if let url = URL(string: song.artworkURL), !song.artworkURL.isEmpty {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(white: 0.15))
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    
                    VStack(spacing: 8) {
                        if !song.name.isEmpty {
                            Text(song.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                        
                        if !song.artistName.isEmpty {
                            Text("by \(song.artistName)")
                                .font(.system(size: 15))
                                .foregroundStyle(Color(white: 0.6))
                        }
                        
                        if song.duration > 0 {
                            Text(formattedDuration)
                                .font(.system(size: 13))
                                .foregroundStyle(Color(white: 0.5))
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 12)
                    
                    VStack(spacing: 12) {
                        if !song.linkToSong.isEmpty, let songUrl = URL(string: song.linkToSong) {
                            Link(destination: songUrl) {
                                HStack {
                                    Label("Open song on SoundCloud", systemImage: "music.note")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(minHeight: 44)
                                .background(Color(white: 0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color(white: 0.25), lineWidth: 1)
                                )
                            }
                        }
                        
                        if !song.linkToArtist.isEmpty, let artistUrl = URL(string: song.linkToArtist) {
                            Link(destination: artistUrl) {
                                HStack {
                                    Label("Open artist on SoundCloud", systemImage: "person.fill")
                                        .font(.system(size: 15, weight: .medium))
                                    Spacer()
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(minHeight: 44)
                                .background(Color(white: 0.12))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color(white: 0.25), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(20)
                .frame(maxWidth: 300)
                .background(Color(white: 0.1))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color(white: 0.2), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.5), radius: 24, x: 0, y: 12)
                .padding(.horizontal, 20)
        }
    }
    
    var formattedDuration: String {
        let totalSeconds = song.duration / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    func onPlay() {
        print("Not implemented: \(song.name) (\(song.songId))")
    }
}
