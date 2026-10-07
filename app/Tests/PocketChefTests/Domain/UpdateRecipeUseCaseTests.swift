@testable import PocketChef
import XCTest

private final class FakeRecipeRepository: RecipeRepository {
    var updateResult: Result<Void, Error> = .success(())
    private(set) var updatedRecipes: [Recipe] = []

    func fetchAll() throws -> [Recipe] { [] }
    func create(_: Recipe, newPhotos _: [UUID: ProcessedPhoto]) throws {}

    private(set) var newPhotos: [[UUID: ProcessedPhoto]] = []

    func update(_ recipe: Recipe, newPhotos: [UUID: ProcessedPhoto]) throws {
        updatedRecipes.append(recipe)
        self.newPhotos.append(newPhotos)
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
        XCTAssertEqual(repository.newPhotos, [[:]])
    }

    func testExecutePassesNewPhotoBytesToRepository() throws {
        let repository = FakeRecipeRepository()
        let useCase = DefaultUpdateRecipeUseCase(repository: repository)
        let photoID = UUID()
        let bytes = ProcessedPhoto(imageData: Data([1]), thumbnailData: Data([2]))
        var recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        recipe.photos = [RecipePhoto(id: photoID)]

        try useCase.execute(recipe, newPhotos: [photoID: bytes])

        XCTAssertEqual(repository.updatedRecipes, [recipe])
        XCTAssertEqual(repository.newPhotos, [[photoID: bytes]])
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
