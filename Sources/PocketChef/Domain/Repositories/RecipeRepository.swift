import Foundation

protocol RecipeRepository {
    func fetchAll() throws -> [Recipe]
}
