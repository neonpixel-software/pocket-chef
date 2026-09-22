@testable import PocketChef
import XCTest

private final class FakeRecipeRepository: RecipeRepository {
    var createResult: Result<Void, Error> = .success(())
    private(set) var createdRecipes: [Recipe] = []

    func fetchAll() throws -> [Recipe] { [] }

    func create(_ recipe: Recipe) throws {
        createdRecipes.append(recipe)
        try createResult.get()
    }

    func update(_: Recipe) throws {}
    func delete(id _: UUID) throws {}
}

private struct RepositoryFailure: Error, Equatable {}

final class CreateRecipeUseCaseTests: XCTestCase {
    func testExecutePassesRecipeToRepository() throws {
        let repository = FakeRecipeRepository()
        let useCase = DefaultCreateRecipeUseCase(repository: repository)
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])

        try useCase.execute(recipe)

        XCTAssertEqual(repository.createdRecipes, [recipe])
    }

    func testExecutePropagatesRepositoryError() {
        let repository = FakeRecipeRepository()
        repository.createResult = .failure(RepositoryFailure())
        let useCase = DefaultCreateRecipeUseCase(repository: repository)
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])

        XCTAssertThrowsError(try useCase.execute(recipe)) { error in
            XCTAssertTrue(error is RepositoryFailure)
        }
    }
}
