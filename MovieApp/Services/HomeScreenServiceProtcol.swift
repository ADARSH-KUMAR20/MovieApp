//
//  HomeScreenServiceProtcol.swift
//  MovieApp
//
//  Created by LT-MAC-04 on 25/10/26.
//

import Foundation

/// Primary protocol defining operations available on the Home screen
protocol HomeScreenServiceProtocol {
    func searchMovies(query: String, page: Int) async throws -> (movies: [Movie], totalResults: Int)
    func fetchMovieDetail(imdbID: String) async throws -> MovieDetail
    func prefetchPosters(for movies: [Movie])
    func toggleFavorite(movie: Movie) -> Bool
    func isFavorite(movieID: String) -> Bool
    func fetchAllFavorites() -> [Movie]
}

/// Legacy/draft protocol preserved with default implementations for backward compatibility
protocol HomeScreenService: HomeScreenServiceProtocol {
    func searchMovie()
    func showMoviesList()
    func showMovieDetail()
    func markFav()
    func likeMovie()
    func viewPoster()
}

extension HomeScreenService {
    func searchMovie() {}
    func showMoviesList() {}
    func showMovieDetail() {}
    func markFav() {}
    func likeMovie() {}
    func viewPoster() {}
}
