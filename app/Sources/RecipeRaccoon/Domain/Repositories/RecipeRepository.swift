import Foundation

protocol RecipeRepository {
    func fetchAll() throws -> [Recipe]
    /// `newPhotos` holds the bytes of photos in `recipe.photos` that aren't stored yet.
    /// A photo with neither a stored row nor bytes is skipped.
    func create(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws
    /// Stored photos missing from `recipe.photos` are deleted; the rest take its order.
    func update(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws
    func delete(id: UUID) throws
}

extension RecipeRepository {
    func create(_ recipe: Recipe) throws {
        try create(recipe, newPhotos: [:])
    }

    func update(_ recipe: Recipe) throws {
        try update(recipe, newPhotos: [:])
    }
}

enum RecipeRepositoryError: LocalizedError, Equatable {
    case recipeNotFound

    var errorDescription: String? {
        switch self {
        case .recipeNotFound:
            String(localized: "This recipe couldn't be found. It may have already been deleted.")
        }
    }
}
