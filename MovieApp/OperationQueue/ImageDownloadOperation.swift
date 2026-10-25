//
//  ImageDownloadOperation.swift
//  MovieApp
//

import UIKit

/// Asynchronous concurrent Operation subclass for downloading an image in the background
final class ImageDownloadOperation: Operation, @unchecked Sendable {
    enum State: String {
        case ready = "isReady"
        case executing = "isExecuting"
        case finished = "isFinished"
    }

    let urlString: String
    private(set) var downloadedImage: UIImage?
    private(set) var error: Error?

    private var dataTask: URLSessionDataTask?
    private var completionBlocks: [(UIImage?, Error?) -> Void] = []
    private let stateLock = NSRecursiveLock()

    private var _state: State = .ready

    private var state: State {
        get {
            stateLock.lock()
            defer { stateLock.unlock() }
            return _state
        }
        set {
            stateLock.lock()
            let oldValue = _state
            stateLock.unlock()

            willChangeValue(forKey: oldValue.rawValue)
            willChangeValue(forKey: newValue.rawValue)

            stateLock.lock()
            _state = newValue
            stateLock.unlock()

            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: newValue.rawValue)
        }
    }

    override var isReady: Bool {
        return super.isReady && state == .ready
    }

    override var isExecuting: Bool {
        return state == .executing
    }

    override var isFinished: Bool {
        return state == .finished
    }

    override var isAsynchronous: Bool {
        return true
    }

    init(urlString: String, completion: ((UIImage?, Error?) -> Void)? = nil) {
        self.urlString = urlString
        super.init()
        if let completion = completion {
            self.completionBlocks.append(completion)
        }
    }

    /// Attach an additional completion handler (useful if multiple views request the same image)
    func addCompletionHandler(_ completion: @escaping (UIImage?, Error?) -> Void) {
        stateLock.lock()
        defer { stateLock.unlock() }
        if state == .finished {
            let image = downloadedImage
            let err = error
            DispatchQueue.main.async {
                completion(image, err)
            }
        } else {
            completionBlocks.append(completion)
        }
    }

    override func start() {
        if isCancelled {
            finish()
            return
        }

        // 1. First check NSCache before triggering network request
        if let cachedImage = ImageCacheManager.shared.image(forKey: urlString) {
            self.downloadedImage = cachedImage
            notifyCompletion(image: cachedImage, error: nil)
            finish()
            return
        }

        guard let url = URL(string: urlString) else {
            let invalidURLError = NSError(
                domain: "ImageDownloadOperation",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL string: \(urlString)"]
            )
            self.error = invalidURLError
            notifyCompletion(image: nil, error: invalidURLError)
            finish()
            return
        }

        state = .executing

        dataTask = URLSession.shared.dataTask(with: url) { [weak self] data, response, taskError in
            guard let self = self else { return }

            defer { self.finish() }

            if self.isCancelled {
                return
            }

            if let taskError = taskError {
                self.error = taskError
                self.notifyCompletion(image: nil, error: taskError)
                return
            }

            guard let data = data, let image = UIImage(data: data) else {
                let parseError = NSError(
                    domain: "ImageDownloadOperation",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Unable to decode image from data"]
                )
                self.error = parseError
                self.notifyCompletion(image: nil, error: parseError)
                return
            }

            // Save decoded image into NSCache
            ImageCacheManager.shared.insertImage(image, forKey: self.urlString)
            self.downloadedImage = image
            self.notifyCompletion(image: image, error: nil)
        }

        dataTask?.resume()
    }

    override func cancel() {
        stateLock.lock()
        dataTask?.cancel()
        dataTask = nil
        stateLock.unlock()
        super.cancel()
        if isExecuting {
            finish()
        }
    }

    private func finish() {
        state = .finished
    }

    private func notifyCompletion(image: UIImage?, error: Error?) {
        stateLock.lock()
        let handlers = completionBlocks
        completionBlocks.removeAll()
        stateLock.unlock()

        DispatchQueue.main.async {
            handlers.forEach { $0(image, error) }
        }
    }
}
