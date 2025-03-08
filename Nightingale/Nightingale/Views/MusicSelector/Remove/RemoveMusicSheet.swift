import SwiftUI

struct RemoveMusicSheet: View {
    @Binding var successfullyRemoved: Bool
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var musicLibrary = MusicLibrary.shared
    @State private var selectedSongs: Set<Song> = []

    var body: some View {
        NavigationView {
            List(musicLibrary.songs, id: \.id, selection: $selectedSongs) { song in
                HStack {
                    Text(song.fileName)
                    Spacer()
                    if selectedSongs.contains(song) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedSongs.contains(song) {
                        selectedSongs.remove(song)
                    } else {
                        selectedSongs.insert(song)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Remove Music")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Remove") {
                        removeSelectedSongs()
                    }
                    .disabled(selectedSongs.isEmpty)
                }
            }
        }
    }

    private func removeSelectedSongs() {
        for song in selectedSongs {
            musicLibrary.removeMusicFile(song)
        }
        selectedSongs.removeAll()
        successfullyRemoved = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            successfullyRemoved = false
        }
        presentationMode.wrappedValue.dismiss()
    }
}
