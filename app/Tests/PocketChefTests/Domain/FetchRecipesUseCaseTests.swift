@testable import PocketChef
import XCTest

private struct FakeRecipeRepository: RecipeRepository {
    var result: Result<[Recipe], Error>

    func fetchAll() throws -> [Recipe] {
        try result.get()
    }

    func create(_: Recipe) throws {}
    func update(_: Recipe) throws {}
    func delete(id _: UUID) throws {}
}

private struct RepositoryFailure: Error, Equatable {}

final class FetchRecipesUseCaseTests: XCTestCase {
    func testExecuteReturnsRecipesFromRepository() throws {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let useCase = DefaultFetchRecipesUseCase(repository: FakeRecipeRepository(result: .success([recipe])))

        let recipes = try useCase.execute()

        XCTAssertEqual(recipes, [recipe])
    }

    func testExecutePropagatesRepositoryError() {
        let useCase = DefaultFetchRecipesUseCase(repository: FakeRecipeRepository(result: .failure(RepositoryFailure())))

        XCTAssertThrowsError(try useCase.execute()) { error in
            XCTAssertTrue(error is RepositoryFailure)
        }
    }
}
