//
//  DiskImageCacheManager.swift
//  MovieApp
//

import UIKit

/// Manages persistent disk-level caching in the application Caches directory
final class DiskImageCacheManager {
    static let shared = DiskImageCacheManager()

    private let fileManager = FileManager.default
    private let cacheDirectoryURL: URL

    private init() {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectoryURL = paths[0].appendingPathComponent("MoviePosters", isDirectory: true)

        if !fileManager.fileExists(atPath: cacheDirectoryURL.path) {
            try? fileManager.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true)
        }
    }

    /// Generates a safe file path for a given URL string
    private func filePath(for urlString: String) -> URL {
        let filename = "\(urlString.hashValue).jpg"
        return cacheDirectoryURL.appendingPathComponent(filename)
    }

    /// Retrieve image from disk cache
    func image(forKey key: String) -> UIImage? {
        let fileURL = filePath(for: key)
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        return image
    }

    /// Retrieve raw binary data from disk cache
    func data(forKey key: String) -> Data? {
        let fileURL = filePath(for: key)
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        return try? Data(contentsOf: fileURL)
    }

    /// Store image on disk
    func store(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.85) else { return }
        let fileURL = filePath(for: key)
        try? data.write(to: fileURL)
    }

    /// Store raw data directly on disk
    func store(data: Data, forKey key: String) {
        let fileURL = filePath(for: key)
        try? data.write(to: fileURL)
    }

    /// Check if image exists on disk
    func exists(forKey key: String) -> Bool {
        return fileManager.fileExists(atPath: filePath(for: key).path)
    }
}
