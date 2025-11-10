import SwiftUI

struct CachedAsyncImage<Content: View>: View {
    let url: URL?
    let content: (Image?) -> Content

    @StateObject private var loader = RemoteImageLoader()

    var body: some View {
        content(loader.image.map { Image(uiImage: $0) })
            .onAppear {
                if let url {
                    loader.load(from: url)
                }
            }
            .onDisappear {
                loader.cancel()
            }
    }
}
