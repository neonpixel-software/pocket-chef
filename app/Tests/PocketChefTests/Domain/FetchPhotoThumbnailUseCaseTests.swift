@testable import PocketChef
import XCTest

private struct FakeRecipePhotoRepository: RecipePhotoRepository {
    var thumbnails: [UUID: Data] = [:]
    var error: Error?

    func thumbnail(id: UUID) throws -> Data? {
        if let error { throw error }
        return thumbnails[id]
    }

    func image(id _: UUID) throws -> Data? { nil }
}

private struct RepositoryFailure: Error {}

final class FetchPhotoThumbnailUseCaseTests: XCTestCase {
    func testExecuteReturnsTheRepositorysThumbnail() throws {
        let id = UUID()
        let useCase = DefaultFetchPhotoThumbnailUseCase(repository: FakeRecipePhotoRepository(thumbnails: [id: Data([1, 2])]))

        XCTAssertEqual(try useCase.execute(id: id), Data([1, 2]))
        XCTAssertNil(try useCase.execute(id: UUID()))
    }

    func testExecutePropagatesRepositoryError() {
        let useCase = DefaultFetchPhotoThumbnailUseCase(repository: FakeRecipePhotoRepository(error: RepositoryFailure()))

        XCTAssertThrowsError(try useCase.execute(id: UUID())) { error in
            XCTAssertTrue(error is RepositoryFailure)
        }
    }
}
