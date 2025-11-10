import UIKit

protocol ImageCacheType: AnyObject {
    subscript(_ url: URL) -> UIImage? { get set }
}

final class ImageCache: ImageCacheType {
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    subscript(_ url: URL) -> UIImage? {
        get { cache.object(forKey: url as NSURL) }
        set {
            if let newValue {
                cache.setObject(newValue, forKey: url as NSURL)
            } else {
                cache.removeObject(forKey: url as NSURL)
            }
        }
    }
}
