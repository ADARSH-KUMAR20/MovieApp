//
//  Movie.swift
//  MovieApp
//

import Foundation

/// Response structure returned by OMDb API search endpoint
struct MovieSearchResponse: Codable {
    let search: [Movie]?
    let totalResults: String?
    let response: String
    let error: String?

    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
        case error = "Error"
    }
}

/// Model representing an individual Movie from OMDb API
struct Movie: Codable, Identifiable, Equatable, Hashable {
    let title: String
    let year: String
    let imdbID: String
    let type: String
    let poster: String

    var id: String { imdbID }

    /// Checks if the movie has a valid HTTP/HTTPS poster URL
    var hasValidPoster: Bool {
        poster != "N/A" && !poster.isEmpty && URL(string: poster) != nil
    }

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case imdbID
        case type = "Type"
        case poster = "Poster"
    }
}
