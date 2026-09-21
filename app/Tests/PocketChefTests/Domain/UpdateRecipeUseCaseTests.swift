@testable import PocketChef
import XCTest

private final class FakeRecipeRepository: RecipeRepository {
    var updateResult: Result<Void, Error> = .success(())
    private(set) var updatedRecipes: [Recipe] = []

    func fetchAll() throws -> [Recipe] { [] }
    func create(_: Recipe) throws {}

    func update(_ recipe: Recipe) throws {
        updatedRecipes.append(recipe)
        try updateResult.get()
    }

    func delete(id _: UUID) throws {}
}

private struct RepositoryFailure: Error, Equatable {}

final class UpdateRecipeUseCaseTests: XCTestCase {
    func testExecutePassesRecipeToRepository() throws {
        let repository = FakeRecipeRepository()
        let useCase = DefaultUpdateRecipeUseCase(repository: repository)
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])

        try useCase.execute(recipe)

        XCTAssertEqual(repository.updatedRecipes, [recipe])
    }

    func testExecutePropagatesRepositoryError() {
        let repository = FakeRecipeRepository()
        repository.updateResult = .failure(RepositoryFailure())
        let useCase = DefaultUpdateRecipeUseCase(repository: repository)
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])

        XCTAssertThrowsError(try useCase.execute(recipe)) { error in
            XCTAssertTrue(error is RepositoryFailure)
        }
    }
}
