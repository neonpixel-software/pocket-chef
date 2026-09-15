import Foundation

protocol CreateRecipeUseCase {
    func execute(_ recipe: Recipe) throws
}

final class DefaultCreateRecipeUseCase: CreateRecipeUseCase {
    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func execute(_ recipe: Recipe) throws {
        try repository.create(recipe)
    }
}
