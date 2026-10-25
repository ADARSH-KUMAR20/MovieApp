//
//  MovieRowView.swift
//  MovieApp
//

import SwiftUI

/// Modern card component featuring a prominent square thumbnail, metadata, and quick actions
struct MovieRowView: View {
    let movie: Movie
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let onViewPoster: () -> Void
    let onSelect: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            // Prominent Square Poster Image
            CachedAsyncImageView(urlString: movie.poster, contentMode: .fill)
                .frame(width: 115, height: 115)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 3)

            // Movie Info & Actions
            VStack(alignment: .leading, spacing: 6) {
                // Title
                Text(movie.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Badges (Year & Type)
                HStack(spacing: 6) {
                    Text(movie.year)
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.12))
                        .foregroundColor(.blue)
                        .clipShape(Capsule())

                    Text(movie.type.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Color.purple.opacity(0.12))
                        .foregroundColor(.purple)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }

                Spacer(minLength: 4)

                // Quick Actions Row
                HStack(spacing: 10) {
                    // Eye Button (View Poster Preview)
                    Button(action: onViewPoster) {
                        HStack(spacing: 4) {
                            Image(systemName: "eye.fill")
                                .font(.system(size: 12, weight: .medium))
                            Text("Poster")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color(.tertiarySystemFill))
                        .foregroundColor(.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)

                    // Heart Button (Toggle Favorite)
                    Button(action: onToggleFavorite) {
                        HStack(spacing: 4) {
                            Image(systemName: isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(isFavorite ? .red : .secondary)
                                .scaleEffect(isFavorite ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFavorite)

                            Text(isFavorite ? "Saved" : "Favorite")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isFavorite ? .red : .secondary)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(isFavorite ? Color.red.opacity(0.12) : Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)

                    Spacer()

                    // Chevron indicating navigation
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}
