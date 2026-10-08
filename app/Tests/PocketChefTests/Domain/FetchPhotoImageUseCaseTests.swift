@testable import PocketChef
import XCTest

private struct FakeRecipePhotoRepository: RecipePhotoRepository {
    var images: [UUID: Data] = [:]
    var error: Error?

    func image(id: UUID) throws -> Data? {
        if let error { throw error }
        return images[id]
    }

    func thumbnail(id _: UUID) throws -> Data? { nil }
}

private struct RepositoryFailure: Error {}

final class FetchPhotoImageUseCaseTests: XCTestCase {
    func testExecuteReturnsTheRepositorysImage() throws {
        let id = UUID()
        let useCase = DefaultFetchPhotoImageUseCase(repository: FakeRecipePhotoRepository(images: [id: Data([1, 2])]))

        XCTAssertEqual(try useCase.execute(id: id), Data([1, 2]))
        XCTAssertNil(try useCase.execute(id: UUID()))
    }

    func testExecutePropagatesRepositoryError() {
        let useCase = DefaultFetchPhotoImageUseCase(repository: FakeRecipePhotoRepository(error: RepositoryFailure()))

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertTrue(error is RepositoryFailure)
        }
    }
}
