import XCTest
@testable import PocketChef

private final class FakeRecipeRepository: RecipeRepository {
    var deleteResult: Result<Void, Error> = .success(())
    private(set) var deletedIDs: [UUID] = []

    func fetchAll() throws -> [Recipe] { [] }
    func create(_ recipe: Recipe) throws {}
    func update(_ recipe: Recipe) throws {}

    func delete(id: UUID) throws {
        deletedIDs.append(id)
        try deleteResult.get()
    }
}

private struct RepositoryFailure: Error, Equatable {}

final class DeleteRecipeUseCaseTests: XCTestCase {
    func testExecutePassesIDToRepository() throws {
        let repository = FakeRecipeRepository()
        let useCase = DefaultDeleteRecipeUseCase(repository: repository)
        let id = UUID()

        try useCase.execute(id: id)

        XCTAssertEqual(repository.deletedIDs, [id])
    }

    func testExecutePropagatesRepositoryError() {
        let repository = FakeRecipeRepository()
        repository.deleteResult = .failure(RepositoryFailure())
        let useCase = DefaultDeleteRecipeUseCase(repository: repository)

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertTrue(error is RepositoryFailure)
        }
    }
}
