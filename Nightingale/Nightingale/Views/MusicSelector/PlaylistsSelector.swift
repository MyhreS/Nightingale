import SwiftUI

struct PlaylistsSelector: View {
    @Binding var selectedPlaylist: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                TagButton(tag: "All", isSelected: selectedPlaylist == "All") {
                    selectedPlaylist = "All"
                    provideHapticFeedback()
                }
                
                    TagButton(tag: "Some playlist", isSelected: selectedPlaylist == "Some playlist") {
                        selectedPlaylist = "Some playlist"
                        provideHapticFeedback()
                    }
            }
            .padding(.horizontal, 5)
        }
        .padding(.vertical, 5)
    }
}
