import Foundation

protocol RecipeRepository {
    func fetchAll() throws -> [Recipe]
    func create(_ recipe: Recipe) throws
    func update(_ recipe: Recipe) throws
    func delete(id: UUID) throws
}

enum RecipeRepositoryError: Error, Equatable {
    case recipeNotFound
}
