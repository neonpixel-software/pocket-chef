import Foundation

protocol UpdateRecipeUseCase {
    func execute(_ recipe: Recipe) throws
}

final class DefaultUpdateRecipeUseCase: UpdateRecipeUseCase {
    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func execute(_ recipe: Recipe) throws {
        try repository.update(recipe)
    }
}
