import Foundation

protocol UpdateRecipeUseCase {
    /// `newPhotos` holds the bytes of photos in `recipe.photos` that aren't stored yet.
    func execute(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws
}

extension UpdateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {
        try execute(recipe, newPhotos: [:])
    }
}

final class DefaultUpdateRecipeUseCase: UpdateRecipeUseCase {
    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func execute(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws {
        try repository.update(recipe, newPhotos: newPhotos)
    }
}
