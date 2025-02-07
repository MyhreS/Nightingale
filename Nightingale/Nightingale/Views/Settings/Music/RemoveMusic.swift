import SwiftUI

struct RemoveMusic: View {
    @Binding var isPresented: Bool
    @ObservedObject private var musicLibrary = MusicLibrary.shared
    @State private var selectedSongs: Set<MusicFile> = [] // Stores selected songs
    
    var body: some View {
        NavigationView {
            VStack {
                List(musicLibrary.musicFiles) { song in
                    HStack {
                        Text(song.name)
                            .foregroundColor(selectedSongs.contains(song) ? .red : .primary)
                        
                        Spacer()
                        
                        if selectedSongs.contains(song) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 5)
                    .contentShape(Rectangle()) // Makes entire row tappable
                    .onTapGesture {
                        if selectedSongs.contains(song) {
                            selectedSongs.remove(song)
                        } else {
                            selectedSongs.insert(song)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                
                HStack {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)

                    Button("Remove Selected") {
                        removeSelectedSongs()
                        isPresented = false // Close the sheet
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedSongs.isEmpty ? Color.gray.opacity(0.3) : Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(selectedSongs.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Remove Music")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func removeSelectedSongs() {
        for song in selectedSongs {
            musicLibrary.removeMusicFile(song)
        }
    }
}
