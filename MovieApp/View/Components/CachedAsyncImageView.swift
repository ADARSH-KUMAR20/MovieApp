//
//  CachedAsyncImageView.swift
//  MovieApp
//

import SwiftUI

/// Component responsible for loading, displaying, and caching images via NSCache and OperationQueue
struct CachedAsyncImageView: View {
    let urlString: String
    var contentMode: ContentMode = .fill

    @State private var loadedImage: UIImage?
    @State private var isLoading: Bool = false
    @State private var downloadOperation: ImageDownloadOperation?

    var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .transition(.opacity.animation(.easeInOut(duration: 0.25)))
            } else if isLoading {
                ZStack {
                    Color(.systemGray6)
                    ProgressView()
                        .scaleEffect(0.85)
                }
            } else {
                // Fallback placeholder when no image is available or URL is N/A
                ZStack {
                    LinearGradient(
                        colors: [Color.gray.opacity(0.2), Color.gray.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    VStack(spacing: 4) {
                        Image(systemName: "film")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text("No Poster")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .onAppear {
            loadImage()
        }
        .onDisappear {
            cancelDownload()
        }
        .onChange(of: urlString) { _ in
            loadImage()
        }
    }

    private func loadImage() {
        guard !urlString.isEmpty, urlString != "N/A" else {
            loadedImage = nil
            isLoading = false
            return
        }

        // 1. Check NSCache first
        if let cached = ImageDownloadQueueManager.shared.cachedImage(for: urlString) {
            self.loadedImage = cached
            self.isLoading = false
            return
        }

        // 2. Load via background OperationQueue
        self.isLoading = true
        self.downloadOperation = ImageDownloadQueueManager.shared.loadImage(from: urlString) { image in
            self.loadedImage = image
            self.isLoading = false
            self.downloadOperation = nil
        }
    }

    private func cancelDownload() {
        if let operation = downloadOperation, !operation.isFinished {
            operation.cancel()
            downloadOperation = nil
        }
    }
}
