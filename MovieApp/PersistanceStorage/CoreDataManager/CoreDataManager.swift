//
//  CoreDataManager.swift
//  MovieApp
//

import Foundation
import CoreData

protocol CoreDataManagerProtocol {
    func saveFavorite(movie: Movie, posterData: Data?) throws
    func deleteFavorite(imdbID: String) throws
    func fetchAllFavorites() -> [Movie]
    func isFavorite(imdbID: String) -> Bool
    func fetchPosterData(imdbID: String) -> Data?
}

final class CoreDataManager: CoreDataManagerProtocol {
    static let shared = CoreDataManager()

    let persistentContainer: NSPersistentContainer

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private init() {
        persistentContainer = NSPersistentContainer(name: "MovieDataModel")

        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data stack: \(error)")
            }
        }

        persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Save a movie as a favorite along with optional poster binary data for full offline viewing
    func saveFavorite(movie: Movie, posterData: Data?) throws {
        let request: NSFetchRequest<FavoriteMovieEntity> = FavoriteMovieEntity.fetchRequest()
        request.predicate = NSPredicate(format: "imdbID == %@", movie.imdbID)

        let existing = try context.fetch(request)
        let entity = existing.first ?? FavoriteMovieEntity(context: context)

        entity.imdbID = movie.imdbID
        entity.title = movie.title
        entity.year = movie.year
        entity.type = movie.type
        entity.poster = movie.poster
        entity.savedAt = Date()

        if let posterData = posterData {
            entity.posterData = posterData
        }

        try context.save()
    }

    /// Delete a favorite movie from Core Data
    func deleteFavorite(imdbID: String) throws {
        let request: NSFetchRequest<FavoriteMovieEntity> = FavoriteMovieEntity.fetchRequest()
        request.predicate = NSPredicate(format: "imdbID == %@", imdbID)

        let results = try context.fetch(request)
        for entity in results {
            context.delete(entity)
        }

        if context.hasChanges {
            try context.save()
        }
    }

    /// Retrieve all stored favorites ordered by saved date descending
    func fetchAllFavorites() -> [Movie] {
        let request: NSFetchRequest<FavoriteMovieEntity> = FavoriteMovieEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "savedAt", ascending: false)]

        do {
            let entities = try context.fetch(request)
            return entities.map { $0.toMovie() }
        } catch {
            return []
        }
    }

    /// Check if a movie is currently favorited in Core Data
    func isFavorite(imdbID: String) -> Bool {
        let request: NSFetchRequest<FavoriteMovieEntity> = FavoriteMovieEntity.fetchRequest()
        request.predicate = NSPredicate(format: "imdbID == %@", imdbID)
        request.fetchLimit = 1

        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }

    /// Retrieve offline cached poster image data from Core Data
    func fetchPosterData(imdbID: String) -> Data? {
        let request: NSFetchRequest<FavoriteMovieEntity> = FavoriteMovieEntity.fetchRequest()
        request.predicate = NSPredicate(format: "imdbID == %@", imdbID)
        request.fetchLimit = 1

        do {
            let results = try context.fetch(request)
            return results.first?.posterData
        } catch {
            return nil
        }
    }
}
