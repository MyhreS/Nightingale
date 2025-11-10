import SwiftUI

@MainActor
final class RemoteImageLoader: ObservableObject {
    @Published var image: UIImage?

    private let cache: ImageCacheType
    private var task: Task<Void, Never>?

    init(cache: ImageCacheType = ImageCache.shared) {
        self.cache = cache
    }

    func load(from url: URL) {
        if let cached = cache[url] {
            image = cached
            return
        }

        task?.cancel()

        task = Task {
            let result = await fetchImage(from: url)
            guard !Task.isCancelled else { return }

            if let loaded = result {
                cache[url] = loaded
                image = loaded
            }
        }
    }

    func cancel() {
        task?.cancel()
    }

    private func fetchImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
}
