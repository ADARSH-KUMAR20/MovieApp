//
//  MovieListView.swift
//  MovieApp
//

import SwiftUI

struct MovieListView: View {
    @StateObject private var viewModel = MovieListViewModel()
    @State private var selectedMovieForDetail: Movie?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Switcher (All Movies vs Favorites)
                topFilterSwitcher

                // Search Bar Header
                searchHeader

                // Main Content
                ZStack {
                    Color(.systemGroupedBackground)
                        .ignoresSafeArea()

                    if viewModel.isLoading {
                        loadingView
                    } else if let error = viewModel.errorMessage, viewModel.selectedFilter == .all {
                        errorView(message: error)
                    } else if viewModel.displayedMovies.isEmpty {
                        emptyStateView
                    } else {
                        movieListContent
                    }
                }
            }
            .navigationTitle("Movies")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        viewModel.searchQuery = ""
                        viewModel.loadRandomMovies()
                    }) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Show Random 10 Movies")
                }
            }
            .navigationDestination(item: $selectedMovieForDetail) { movie in
                MovieDetailView(
                    movie: movie,
                    isFavorite: viewModel.isFavorite(movie: movie),
                    onToggleFavorite: {
                        viewModel.toggleFavorite(movie: movie)
                    }
                )
            }
            .onAppear {
                viewModel.loadPersistedFavorites()
            }
            .sheet(item: $viewModel.selectedMovieForPoster) { movie in
                PosterDetailModal(movie: movie) {
                    viewModel.dismissPoster()
                }
            }
        }
    }

    // MARK: - Top Filter Switcher
    private var topFilterSwitcher: some View {
        HStack(spacing: 10) {
            ForEach(MovieFilterTab.allCases) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedFilter = tab
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab == .all ? "film.fill" : "heart.fill")
                            .font(.system(size: 12, weight: .semibold))

                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .semibold))

                        // Counter Badge
                        let count = tab == .all ? viewModel.movies.count : viewModel.favoriteMovies.count
                        if count > 0 {
                            Text("\(count)")
                                .font(.system(size: 11, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    viewModel.selectedFilter == tab
                                    ? Color.white.opacity(0.28)
                                    : Color.secondary.opacity(0.18)
                                )
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(
                        viewModel.selectedFilter == tab
                        ? (tab == .favorites ? Color.red : Color.blue)
                        : Color(.secondarySystemBackground)
                    )
                    .foregroundColor(viewModel.selectedFilter == tab ? .white : .primary)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color(.systemBackground))
    }

    // MARK: - Search Header
    private var searchHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField(
                viewModel.selectedFilter == .all
                ? "Search any movie or series..."
                : "Filter marked favorites...",
                text: $viewModel.searchQuery
            )
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)
            .submitLabel(.search)
            .onSubmit {
                if viewModel.selectedFilter == .all {
                    viewModel.performSearch(query: viewModel.searchQuery)
                }
            }

            if !viewModel.searchQuery.isEmpty {
                Button(action: {
                    viewModel.searchQuery = ""
                    if viewModel.selectedFilter == .all {
                        viewModel.loadRandomMovies()
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(Color(.systemBackground))
    }

    // MARK: - Movie List Content
    private var movieListContent: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                // Results Count Header
                HStack {
                    if viewModel.selectedFilter == .all {
                        Text("Showing \(viewModel.movies.count) of \(viewModel.totalResults) movies")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    } else {
                        Text("\(viewModel.displayedMovies.count) Favorited \(viewModel.displayedMovies.count == 1 ? "Movie" : "Movies")")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Movie Cards (with prominent square thumbnail and full tap navigation)
                ForEach(viewModel.displayedMovies) { movie in
                    MovieRowView(
                        movie: movie,
                        isFavorite: viewModel.isFavorite(movie: movie),
                        onToggleFavorite: {
                            viewModel.toggleFavorite(movie: movie)
                        },
                        onViewPoster: {
                            viewModel.selectPoster(for: movie)
                        },
                        onSelect: {
                            selectedMovieForDetail = movie
                        }
                    )
                    .padding(.horizontal, 16)
                    .onAppear {
                        viewModel.loadNextPageIfNeeded(currentMovie: movie)
                    }
                }

                // Pagination Loading Indicator (All Movies tab only)
                if viewModel.isLoadingNextPage && viewModel.selectedFilter == .all {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading 10 more movies...")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
            }
            .padding(.bottom, 24)
        }
        .refreshable {
            if viewModel.selectedFilter == .all {
                if viewModel.searchQuery.isEmpty {
                    viewModel.loadRandomMovies()
                } else {
                    viewModel.performSearch(query: viewModel.searchQuery)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.3)
            Text("Loading movies...")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            if viewModel.selectedFilter == .favorites {
                Image(systemName: "heart.slash")
                    .font(.system(size: 48))
                    .foregroundColor(.red.opacity(0.8))

                Text("No Favorites Marked Yet")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Tap the heart icon on any movie card to save it to your favorites.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            } else {
                Image(systemName: "film")
                    .font(.system(size: 46))
                    .foregroundColor(.secondary)

                Text("No Movies Found")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Try searching for another movie title.")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 46))
                .foregroundColor(.orange)

            Text("Unable to Load Movies")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button(action: {
                if viewModel.searchQuery.isEmpty {
                    viewModel.loadRandomMovies()
                } else {
                    viewModel.performSearch(query: viewModel.searchQuery)
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 14, weight: .semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 9)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    MovieListView()
}
