@testable import PocketChef
import XCTest

private final class FakeRecipeRepository: RecipeRepository {
    var createResult: Result<Void, Error> = .success(())
    private(set) var createdRecipes: [Recipe] = []

    func fetchAll() throws -> [Recipe] { [] }

    private(set) var newPhotos: [[UUID: ProcessedPhoto]] = []

    func create(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws {
        createdRecipes.append(recipe)
        self.newPhotos.append(newPhotos)
        try createResult.get()
    }

    func update(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}
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
        XCTAssertEqual(repository.newPhotos, [[:]])
    }

    func testExecutePassesNewPhotoBytesToRepository() throws {
        let repository = FakeRecipeRepository()
        let useCase = DefaultCreateRecipeUseCase(repository: repository)
        let photoID = UUID()
        let bytes = ProcessedPhoto(imageData: Data([1]), thumbnailData: Data([2]))
        var recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        recipe.photos = [RecipePhoto(id: photoID)]

        try useCase.execute(recipe, newPhotos: [photoID: bytes])

        XCTAssertEqual(repository.createdRecipes, [recipe])
        XCTAssertEqual(repository.newPhotos, [[photoID: bytes]])
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
