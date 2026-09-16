import Foundation

protocol RecipeRepository {
    func fetchAll() throws -> [Recipe]
    func create(_ recipe: Recipe) throws
    func update(_ recipe: Recipe) throws
    func delete(id: UUID) throws
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
