import UIKit
import CryptoKit

protocol ImageCacheType: AnyObject {
    subscript(_ url: URL) -> UIImage? { get set }
}

final class ImageCache: ImageCacheType {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    
    init() {
        let cachesDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = cachesDir.appendingPathComponent("ArtworkCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    subscript(_ url: URL) -> UIImage? {
        get {
            if let memoryImage = memoryCache.object(forKey: url as NSURL) {
                return memoryImage
            }
            
            if let diskImage = loadFromDisk(url: url) {
                memoryCache.setObject(diskImage, forKey: url as NSURL)
                return diskImage
            }
            
            return nil
        }
        set {
            if let newValue {
                memoryCache.setObject(newValue, forKey: url as NSURL)
                saveToDisk(image: newValue, url: url)
            } else {
                memoryCache.removeObject(forKey: url as NSURL)
                removeFromDisk(url: url)
            }
        }
    }
    
    private func cacheFilePath(for url: URL) -> URL {
        let hash = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = hash.compactMap { String(format: "%02x", $0) }.joined()
        return cacheDirectory.appendingPathComponent(filename)
    }
    
    private func loadFromDisk(url: URL) -> UIImage? {
        let filePath = cacheFilePath(for: url)
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        return UIImage(data: data)
    }
    
    private func saveToDisk(image: UIImage, url: URL) {
        let filePath = cacheFilePath(for: url)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: filePath)
    }
    
    private func removeFromDisk(url: URL) {
        let filePath = cacheFilePath(for: url)
        try? fileManager.removeItem(at: filePath)
    }
}
