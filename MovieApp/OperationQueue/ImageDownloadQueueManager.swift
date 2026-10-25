//
//  ImageDownloadQueueManager.swift
//  MovieApp
//

import UIKit

/// Manages background image downloads using an OperationQueue for full low-level control,
/// concurrency management, tracking, and cancellation.
final class ImageDownloadQueueManager {
    static let shared = ImageDownloadQueueManager()

    /// Background OperationQueue managing concurrent image downloads
    private let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.movieapp.imageDownloadQueue"
        queue.qualityOfService = .userInitiated
        queue.maxConcurrentOperationCount = 4 // Control concurrency so network and CPU aren't saturated
        return queue
    }()

    /// Track active operations keyed by image URL for deduplication and cancellation
    private var activeOperations: [String: ImageDownloadOperation] = [:]
    private let lock = NSRecursiveLock()

    private init() {}

    /// Check whether an image is already cached in NSCache
    func isImageCached(for urlString: String) -> Bool {
        return ImageCacheManager.shared.image(forKey: urlString) != nil
    }

    /// Retrieve directly from cache without hitting network or queue
    func cachedImage(for urlString: String) -> UIImage? {
        return ImageCacheManager.shared.image(forKey: urlString)
    }

    /// Load an image asynchronously:
    /// 1. Synchronously checks NSCache first.
    /// 2. If present, immediately invokes completion.
    /// 3. If absent, queues or attaches to an active Operation on the background OperationQueue.
    @discardableResult
    func loadImage(
        from urlString: String,
        priority: Operation.QueuePriority = .normal,
        completion: @escaping (UIImage?) -> Void
    ) -> ImageDownloadOperation? {
        // Step 1: Check NSCache first
        if let cached = ImageCacheManager.shared.image(forKey: urlString) {
            DispatchQueue.main.async {
                completion(cached)
            }
            return nil
        }

        lock.lock()
        defer { lock.unlock() }

        // Step 2: Check if an operation is already in flight for this URL
        if let existingOperation = activeOperations[urlString], !existingOperation.isFinished {
            existingOperation.addCompletionHandler { image, _ in
                completion(image)
            }
            return existingOperation
        }

        // Step 3: Create a new ImageDownloadOperation and enqueue it
        let operation = ImageDownloadOperation(urlString: urlString) { [weak self] image, error in
            guard let self = self else { return }
            self.lock.lock()
            self.activeOperations.removeValue(forKey: urlString)
            self.lock.unlock()

            completion(image)
        }
        operation.queuePriority = priority

        activeOperations[urlString] = operation
        operationQueue.addOperation(operation)

        return operation
    }

    /// Pre-fetch a batch of up to 10 image URLs on the background queue for smooth scrolling
    func prefetchBatch(urls: [String]) {
        for urlString in urls {
            // Only queue if not already in NSCache and not already running
            if !isImageCached(for: urlString) {
                loadImage(from: urlString, priority: .low) { _ in }
            }
        }
    }

    /// Cancel a specific download (e.g. when a row scrolls out of view before loading)
    func cancelDownload(for urlString: String) {
        lock.lock()
        defer { lock.unlock() }

        if let operation = activeOperations[urlString] {
            operation.cancel()
            activeOperations.removeValue(forKey: urlString)
        }
    }

    /// Cancel all ongoing operations (e.g. when initiating a new search)
    func cancelAll() {
        lock.lock()
        defer { lock.unlock() }

        operationQueue.cancelAllOperations()
        activeOperations.removeAll()
    }

    /// Number of active/queued operations for debugging and monitoring
    var currentOperationCount: Int {
        return operationQueue.operationCount
    }
}
