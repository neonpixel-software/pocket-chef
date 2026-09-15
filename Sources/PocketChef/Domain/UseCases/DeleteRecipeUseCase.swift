import Foundation

protocol DeleteRecipeUseCase {
    func execute(id: UUID) throws
}

final class DefaultDeleteRecipeUseCase: DeleteRecipeUseCase {
    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func execute(id: UUID) throws {
        try repository.delete(id: id)
    }
}
