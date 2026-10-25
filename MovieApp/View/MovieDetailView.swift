//
//  MovieDetailView.swift
//  MovieApp
//

import SwiftUI

struct MovieDetailView: View {
    let movie: Movie
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    @StateObject private var viewModel: MovieDetailViewModel

    init(movie: Movie, isFavorite: Bool, onToggleFavorite: @escaping () -> Void) {
        self.movie = movie
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        _viewModel = StateObject(wrappedValue: MovieDetailViewModel(imdbID: movie.imdbID))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Poster
                heroPosterView

                if viewModel.isLoading {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading details...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else if let error = viewModel.errorMessage {
                    errorCard(message: error)
                } else if let detail = viewModel.detail {
                    detailContent(detail: detail)
                }
            }
            .padding(.bottom, 36)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(movie.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundColor(isFavorite ? .red : .primary)
                        .font(.system(size: 17, weight: .semibold))
                }
                .accessibilityLabel(isFavorite ? "Remove from Favorites" : "Add to Favorites")
            }
        }
    }

    // MARK: - Hero Poster View
    private var heroPosterView: some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImageView(urlString: movie.poster, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .frame(height: 380)
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: Color.black.opacity(0.22), radius: 14, x: 0, y: 7)
                .padding(.horizontal, 16)
                .padding(.top, 10)
        }
    }

    // MARK: - Main Detail Content
    private func detailContent(detail: MovieDetail) -> some View {
        VStack(spacing: 16) {
            // Title & Primary Metadata Card
            VStack(alignment: .leading, spacing: 12) {
                Text(detail.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                // Quick stats pill row
                HStack(spacing: 10) {
                    if detail.rated != "N/A" {
                        Text(detail.rated)
                            .font(.system(size: 12, weight: .bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    }

                    if detail.runtime != "N/A" {
                        Label(detail.runtime, systemImage: "clock")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    Label(detail.year, systemImage: "calendar")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)

                    Spacer()
                }

                // Genre Badges
                if !detail.genresList.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(detail.genresList, id: \.self) { genre in
                                Text(genre)
                                    .font(.system(size: 12, weight: .semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 16)

            // Ratings Card
            ratingsCard(detail: detail)

            // Plot Summary Card
            if detail.plot != "N/A" && !detail.plot.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plot Summary")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text(detail.plot)
                        .font(.system(size: 15))
                        .lineSpacing(4)
                        .foregroundColor(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.horizontal, 16)
            }

            // Cast & Crew Card
            castCard(detail: detail)

            // Additional Info (Awards, BoxOffice, etc.)
            additionalInfoCard(detail: detail)
        }
    }

    // MARK: - Ratings Card
    private func ratingsCard(detail: MovieDetail) -> some View {
        HStack(spacing: 16) {
            // IMDb Score
            if detail.imdbRating != "N/A" {
                VStack(spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                        Text(detail.imdbRating)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                    }
                    Text("\(detail.imdbVotes) votes")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Metascore
            if detail.metascore != "N/A" {
                Divider()
                    .frame(height: 36)

                VStack(spacing: 4) {
                    Text(detail.metascore)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Metascore")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Cast & Crew Card
    private func castCard(detail: MovieDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cast & Crew")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            if detail.director != "N/A" {
                labeledRow(title: "Director", value: detail.director)
            }
            if detail.writer != "N/A" {
                labeledRow(title: "Writers", value: detail.writer)
            }
            if detail.actors != "N/A" {
                labeledRow(title: "Stars", value: detail.actors)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
    }

    // MARK: - Additional Info Card
    private func additionalInfoCard(detail: MovieDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Details")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            if detail.awards != "N/A" {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(detail.awards)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            if let boxOffice = detail.boxOffice, boxOffice != "N/A" {
                labeledRow(title: "Box Office", value: boxOffice)
            }

            if detail.language != "N/A" {
                labeledRow(title: "Language", value: detail.language)
            }

            if detail.country != "N/A" {
                labeledRow(title: "Country", value: detail.country)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .padding(.horizontal, 16)
    }

    private func labeledRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(.primary)
        }
    }

    private func errorCard(message: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundColor(.orange)
            Text("Could not load details")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
            Button("Retry") {
                viewModel.loadDetail()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 6)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 16)
    }
}
