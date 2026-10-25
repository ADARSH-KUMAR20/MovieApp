//
//  MovieDetailViewModel.swift
//  MovieApp
//

import SwiftUI
import Combine

@MainActor
final class MovieDetailViewModel: ObservableObject {
    @Published var detail: MovieDetail?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    let imdbID: String
    private let service: HomeScreenServiceProtocol

    init(imdbID: String, service: HomeScreenServiceProtocol? = nil) {
        self.imdbID = imdbID
        self.service = service ?? HomeScreenServiceImpl()
        loadDetail()
    }

    func loadDetail() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let fetched = try await service.fetchMovieDetail(imdbID: imdbID)
                self.detail = fetched
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
