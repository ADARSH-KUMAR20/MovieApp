//
//  ImageCacheManager.swift
//  MovieApp
//

import UIKit

/// High-performance two-tier image caching architecture:
/// Tier 1: Fast in-memory caching via NSCache
/// Tier 2: Persistent disk-level caching via FileManager for offline capability
final class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let cache = NSCache<NSString, UIImage>()
    private let diskCache = DiskImageCacheManager.shared
    private let lock = NSLock()

    private init() {
        // Cache up to 150 images or ~100MB of uncompressed bitmap data
        cache.countLimit = 150
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearMemory),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Retrieve image: checks Tier 1 (NSCache) first, falls back to Tier 2 (Disk Cache)
    func image(forKey key: String) -> UIImage? {
        lock.lock()
        if let memoryImage = cache.object(forKey: key as NSString) {
            lock.unlock()
            return memoryImage
        }
        lock.unlock()

        // Check persistent disk cache
        if let diskImage = diskCache.image(forKey: key) {
            // Restore to memory cache for fast subsequent reads
            insertIntoMemory(diskImage, forKey: key)
            return diskImage
        }

        return nil
    }

    /// Insert image into both Tier 1 (NSCache) and Tier 2 (Disk Cache)
    func insertImage(_ image: UIImage, forKey key: String) {
        insertIntoMemory(image, forKey: key)
        diskCache.store(image, forKey: key)
    }

    private func insertIntoMemory(_ image: UIImage, forKey key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        lock.lock()
        defer { lock.unlock() }
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    /// Remove a specific image from memory and disk
    func removeImage(forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        cache.removeObject(forKey: key as NSString)
    }

    /// Clear in-memory cache
    @objc func clearMemory() {
        lock.lock()
        defer { lock.unlock() }
        cache.removeAllObjects()
    }
}
