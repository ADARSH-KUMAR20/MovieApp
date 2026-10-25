//
//  MovieNetworkService.swift
//  MovieApp
//

import Foundation

enum NetworkError: LocalizedError {
    case invalidURL
    case serverError(String)
    case decodingError
    case noData
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to create a valid request URL."
        case .serverError(let message):
            return message
        case .decodingError:
            return "Failed to decode movie response from server."
        case .noData:
            return "No data received from the server."
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

protocol MovieNetworkServiceProtocol {
    func searchMovies(query: String, page: Int) async throws -> (movies: [Movie], totalResults: Int)
    func fetchMovieDetail(imdbID: String) async throws -> MovieDetail
}

final class MovieNetworkService: MovieNetworkServiceProtocol {
    static let shared = MovieNetworkService()

    private let baseURL = "https://www.omdbapi.com/"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    /// Search movies with pagination support (10 results per page)
    func searchMovies(query: String, page: Int = 1) async throws -> (movies: [Movie], totalResults: Int) {
        guard var components = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }

        let apiKey = AppConfiguration.apiKey

        components.queryItems = [
            URLQueryItem(name: "s", value: query.trimmingCharacters(in: .whitespacesAndNewlines)),
            URLQueryItem(name: "apikey", value: apiKey),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Invalid HTTP response code.")
        }

        let decoder = JSONDecoder()
        let searchResponse: MovieSearchResponse
        do {
            searchResponse = try decoder.decode(MovieSearchResponse.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }

        if searchResponse.response.lowercased() == "true", let movies = searchResponse.search {
            let total = Int(searchResponse.totalResults ?? "0") ?? movies.count
            return (movies: movies, totalResults: total)
        } else {
            let message = searchResponse.error ?? "No movies found."
            throw NetworkError.serverError(message)
        }
    }

    /// Fetch full movie details by IMDb ID
    func fetchMovieDetail(imdbID: String) async throws -> MovieDetail {
        guard var components = URLComponents(string: baseURL) else {
            throw NetworkError.invalidURL
        }

        let apiKey = AppConfiguration.apiKey

        components.queryItems = [
            URLQueryItem(name: "i", value: imdbID),
            URLQueryItem(name: "plot", value: "full"),
            URLQueryItem(name: "apikey", value: apiKey)
        ]

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError("Invalid HTTP response code.")
        }

        let decoder = JSONDecoder()
        let detail: MovieDetail
        do {
            detail = try decoder.decode(MovieDetail.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }

        if detail.response.lowercased() == "true" {
            return detail
        } else {
            throw NetworkError.serverError("Movie details could not be retrieved.")
        }
    }
}
