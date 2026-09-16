import XCTest
@testable import PocketChef

private struct FakeRecipeCaptureService: RecipeCaptureService {
    var isAvailableResult = true
    var captureResult: Result<Recipe, Error>

    func isAvailable() -> Bool { isAvailableResult }

    func captureRecipe(from text: String) async throws -> Recipe {
        try captureResult.get()
    }
}

private struct CaptureFailure: Error, Equatable {}

final class CaptureRecipeUseCaseTests: XCTestCase {
    func testExecuteReturnsRecipeFromService() async throws {
        let recipe = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let useCase = DefaultCaptureRecipeUseCase(captureService: FakeRecipeCaptureService(captureResult: .success(recipe)))

        let result = try await useCase.execute(text: "some recipe text")

        XCTAssertEqual(result, recipe)
    }

    func testExecutePropagatesServiceError() async {
        let useCase = DefaultCaptureRecipeUseCase(captureService: FakeRecipeCaptureService(captureResult: .failure(CaptureFailure())))

        do {
            _ = try await useCase.execute(text: "some recipe text")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is CaptureFailure)
        }
    }
}
