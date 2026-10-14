import Foundation

protocol FetchRecipesUseCase {
    func execute() throws -> [Recipe]
}

final class DefaultFetchRecipesUseCase: FetchRecipesUseCase {
    private let repository: RecipeRepository

    init(repository: RecipeRepository) {
        self.repository = repository
    }

    func execute() throws -> [Recipe] {
        try repository.fetchAll()
    }
}
