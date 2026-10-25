//
//  FavoriteMovieEntity.swift
//  MovieApp
//

import Foundation
import CoreData

@objc(FavoriteMovieEntity)
public class FavoriteMovieEntity: NSManagedObject {
    @NSManaged public var imdbID: String
    @NSManaged public var title: String
    @NSManaged public var year: String
    @NSManaged public var type: String
    @NSManaged public var poster: String
    @NSManaged public var posterData: Data?
    @NSManaged public var savedAt: Date
}

extension FavoriteMovieEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FavoriteMovieEntity> {
        return NSFetchRequest<FavoriteMovieEntity>(entityName: "FavoriteMovieEntity")
    }

    func toMovie() -> Movie {
        return Movie(
            title: title,
            year: year,
            imdbID: imdbID,
            type: type,
            poster: poster
        )
    }
}
