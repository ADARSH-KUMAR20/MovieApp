//
//  PosterDetailModal.swift
//  MovieApp
//

import SwiftUI

/// Modal sheet presenting full movie poster and key details
struct PosterDetailModal: View {
    let movie: Movie
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Full Poster View
                    CachedAsyncImageView(urlString: movie.poster, contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .frame(height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Details Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text(movie.title)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            Label(movie.year, systemImage: "calendar")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            Label(movie.type.capitalized, systemImage: "film")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("IMDb: \(movie.imdbID)")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .padding(.horizontal)

                    Spacer(minLength: 20)
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Poster Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}
