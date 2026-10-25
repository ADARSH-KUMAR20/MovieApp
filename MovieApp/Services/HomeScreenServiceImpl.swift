//
//  HomeScreenServiceImpl.swift
//  MovieApp
//

import Foundation

final class HomeScreenServiceImpl: HomeScreenService {
    private let networkService: MovieNetworkServiceProtocol
    private let queueManager: ImageDownloadQueueManager
    private let coreDataManager: CoreDataManagerProtocol

    init(
        networkService: MovieNetworkServiceProtocol = MovieNetworkService.shared,
        queueManager: ImageDownloadQueueManager = .shared,
        coreDataManager: CoreDataManagerProtocol = CoreDataManager.shared
    ) {
        self.networkService = networkService
        self.queueManager = queueManager
        self.coreDataManager = coreDataManager
    }

    /// Fetches a page of 10 movies from OMDb API
    func searchMovies(query: String, page: Int) async throws -> (movies: [Movie], totalResults: Int) {
        return try await networkService.searchMovies(query: query, page: page)
    }

    /// Fetches full details for a given movie
    func fetchMovieDetail(imdbID: String) async throws -> MovieDetail {
        return try await networkService.fetchMovieDetail(imdbID: imdbID)
    }

    /// Prefetches images for the current 10 movies using background OperationQueue
    func prefetchPosters(for movies: [Movie]) {
        let validUrls = movies.compactMap { movie -> String? in
            movie.hasValidPoster ? movie.poster : nil
        }
        queueManager.prefetchBatch(urls: validUrls)
    }

    /// Toggle favorite status with full Core Data persistence and offline poster caching
    func toggleFavorite(movie: Movie) -> Bool {
        if coreDataManager.isFavorite(imdbID: movie.imdbID) {
            try? coreDataManager.deleteFavorite(imdbID: movie.imdbID)
            return false
        } else {
            let posterData = DiskImageCacheManager.shared.data(forKey: movie.poster)
            try? coreDataManager.saveFavorite(movie: movie, posterData: posterData)
            return true
        }
    }

    /// Check if a movie is currently marked as favorite in Core Data
    func isFavorite(movieID: String) -> Bool {
        return coreDataManager.isFavorite(imdbID: movieID)
    }

    /// Fetch all favorites saved in Core Data for offline viewing
    func fetchAllFavorites() -> [Movie] {
        return coreDataManager.fetchAllFavorites()
    }
}
