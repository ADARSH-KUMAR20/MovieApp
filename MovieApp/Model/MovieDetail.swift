//
//  MovieDetail.swift
//  MovieApp
//

import Foundation

/// Detailed movie information model returned by OMDb API (`?i={imdbID}`)
struct MovieDetail: Codable, Identifiable, Equatable {
    let title: String
    let year: String
    let rated: String
    let released: String
    let runtime: String
    let genre: String
    let director: String
    let writer: String
    let actors: String
    let plot: String
    let language: String
    let country: String
    let awards: String
    let poster: String
    let ratings: [Rating]?
    let metascore: String
    let imdbRating: String
    let imdbVotes: String
    let imdbID: String
    let type: String
    let boxOffice: String?
    let response: String

    var id: String { imdbID }

    var hasValidPoster: Bool {
        poster != "N/A" && !poster.isEmpty && URL(string: poster) != nil
    }

    var genresList: [String] {
        genre.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    struct Rating: Codable, Equatable, Hashable {
        let source: String
        let value: String

        enum CodingKeys: String, CodingKey {
            case source = "Source"
            case value = "Value"
        }
    }

    enum CodingKeys: String, CodingKey {
        case title = "Title"
        case year = "Year"
        case rated = "Rated"
        case released = "Released"
        case runtime = "Runtime"
        case genre = "Genre"
        case director = "Director"
        case writer = "Writer"
        case actors = "Actors"
        case plot = "Plot"
        case language = "Language"
        case country = "Country"
        case awards = "Awards"
        case poster = "Poster"
        case ratings = "Ratings"
        case metascore = "Metascore"
        case imdbRating
        case imdbVotes
        case imdbID
        case type = "Type"
        case boxOffice = "BoxOffice"
        case response = "Response"
    }
}
