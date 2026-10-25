//
//  MovieListViewModel.swift
//  MovieApp
//

import SwiftUI
import Combine

enum MovieFilterTab: String, CaseIterable, Identifiable {
    case all = "All Movies"
    case favorites = "Favorites"

    var id: String { rawValue }
}

@MainActor
final class MovieListViewModel: ObservableObject {
    @Published var movies: [Movie] = []
    @Published var favoriteMovies: [Movie] = []
    @Published var selectedFilter: MovieFilterTab = .all
    @Published var searchQuery: String = ""
    @Published var isLoading: Bool = false
    @Published var isLoadingNextPage: Bool = false
    @Published var errorMessage: String? = nil
    @Published var totalResults: Int = 0
    @Published var favoriteMovieIDs: Set<String> = []
    @Published var selectedMovieForPoster: Movie? = nil

    private(set) var currentPage: Int = 1
    private(set) var activeQuery: String = ""
    private let homeService: HomeScreenServiceProtocol
    private var searchCancellable: AnyCancellable?
    private var currentSearchTask: Task<Void, Never>?

    private let randomKeywords = [
        "Marvel", "Batman", "Spider-Man", "Inception", "Matrix",
        "Avatar", "Star Wars", "Jurassic", "Mission", "Gladiator",
        "Interstellar", "Avengers", "Sherlock", "Bond", "Transformers",
        "Harry Potter"
    ]

    var hasMorePages: Bool {
        return movies.count < totalResults
    }

    /// Movies to be displayed based on the selected tab filter (All vs Favorites)
    var displayedMovies: [Movie] {
        switch selectedFilter {
        case .all:
            return movies
        case .favorites:
            let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                return favoriteMovies
            } else {
                return favoriteMovies.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
            }
        }
    }

    init(homeService: HomeScreenServiceProtocol? = nil) {
        self.homeService = homeService ?? HomeScreenServiceImpl()
        loadPersistedFavorites()
        setupSearchDebounce()
        // Automatically load 10 random movies on launch
        loadRandomMovies()
    }

    /// Load persisted favorites from Core Data
    func loadPersistedFavorites() {
        self.favoriteMovies = homeService.fetchAllFavorites()
        self.favoriteMovieIDs = Set(self.favoriteMovies.map { $0.id })
    }

    /// Automatically perform search after user pauses typing (500ms debounce)
    private func setupSearchDebounce() {
        searchCancellable = $searchQuery
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                guard let self = self else { return }
                // Only trigger network search if viewing "All Movies"
                if self.selectedFilter == .all {
                    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.count >= 2 {
                        self.performSearch(query: trimmed)
                    } else if trimmed.isEmpty {
                        self.loadRandomMovies()
                    }
                }
            }
    }

    /// Automatically loads 10 random movies
    func loadRandomMovies() {
        let keyword = randomKeywords.randomElement() ?? "Marvel"
        let randomPage = Int.random(in: 1...3)
        fetchMovies(query: keyword, page: randomPage, isNewSearch: true)
    }

    /// User-initiated search trigger (Page 1)
    func performSearch(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            loadRandomMovies()
            return
        }
        fetchMovies(query: trimmed, page: 1, isNewSearch: true)
    }

    /// Core method to fetch a batch of 10 movies and download their 10 images in background
    private func fetchMovies(query: String, page: Int, isNewSearch: Bool) {
        currentSearchTask?.cancel()

        // Cancel previous image download operations in background queue
        ImageDownloadQueueManager.shared.cancelAll()

        activeQuery = query
        currentPage = page
        errorMessage = nil
        isLoading = true

        currentSearchTask = Task {
            do {
                let result = try await homeService.searchMovies(query: query, page: page)
                guard !Task.isCancelled else { return }

                self.movies = result.movies
                self.totalResults = result.totalResults
                self.isLoading = false

                // Pre-fetch only the 10 images on the background OperationQueue
                self.homeService.prefetchPosters(for: result.movies)
            } catch {
                guard !Task.isCancelled else { return }
                self.movies = []
                self.totalResults = 0
                self.isLoading = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    /// Pagination: Triggered when user scrolls near the bottom of the 10 movies
    func loadNextPageIfNeeded(currentMovie: Movie) {
        // Do not paginate when browsing marked favorites
        guard selectedFilter == .all else { return }

        guard let index = movies.firstIndex(where: { $0.id == currentMovie.id }),
              index >= max(0, movies.count - 4),
              hasMorePages,
              !isLoading,
              !isLoadingNextPage else {
            return
        }

        let nextPage = currentPage + 1
        isLoadingNextPage = true

        Task {
            do {
                let query = activeQuery.isEmpty ? (randomKeywords.randomElement() ?? "Movie") : activeQuery
                let result = try await homeService.searchMovies(query: query, page: nextPage)
                guard !Task.isCancelled else { return }

                // Filter duplicates by imdbID
                let existingIDs = Set(self.movies.map { $0.id })
                let newUniqueMovies = result.movies.filter { !existingIDs.contains($0.id) }

                self.movies.append(contentsOf: newUniqueMovies)
                self.currentPage = nextPage
                self.totalResults = result.totalResults
                self.isLoadingNextPage = false

                // Download only the new batch of 10 images in background OperationQueue
                self.homeService.prefetchPosters(for: newUniqueMovies)
            } catch {
                guard !Task.isCancelled else { return }
                self.isLoadingNextPage = false
            }
        }
    }

    /// Toggle favorite status for a movie with Core Data persistence
    func toggleFavorite(movie: Movie) {
        _ = homeService.toggleFavorite(movie: movie)
        loadPersistedFavorites()
    }

    /// Check if a movie is favorite
    func isFavorite(movie: Movie) -> Bool {
        return favoriteMovieIDs.contains(movie.id)
    }

    /// Open poster preview modal
    func selectPoster(for movie: Movie) {
        selectedMovieForPoster = movie
    }

    /// Dismiss poster preview modal
    func dismissPoster() {
        selectedMovieForPoster = nil
    }

    /// Reset search results and reload 10 random movies
    func resetSearch() {
        currentSearchTask?.cancel()
        searchQuery = ""
        loadRandomMovies()
    }
}
