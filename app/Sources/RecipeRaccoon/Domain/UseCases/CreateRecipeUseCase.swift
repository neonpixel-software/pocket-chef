import Foundation

protocol CreateRecipeUseCase {
    /// `newPhotos` holds the bytes of photos in `recipe.photos` that aren't stored yet.
    func execute(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws
}

extension CreateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {
        try execute(recipe, newPhotos: [:])
    }
}

final class DefaultCreateRecipeUseCase: CreateRecipeUseCase {
    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func execute(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws {
        try repository.create(recipe, newPhotos: newPhotos)
    }
}
