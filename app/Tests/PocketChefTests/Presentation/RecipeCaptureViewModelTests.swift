@testable import PocketChef
import XCTest

private struct FakeCaptureRecipeUseCase: CaptureRecipeUseCase {
    var result: Result<Recipe, Error>

    func execute(text _: String) async throws -> Recipe {
        try result.get()
    }
}

private struct CaptureFailure: Error, Equatable {}

@MainActor
final class RecipeCaptureViewModelTests: XCTestCase {
    func testCanCaptureIsFalseWhenTextIsBlankOrWhitespace() {
        let viewModel = RecipeCaptureViewModel(captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(makeRecipe())))

        viewModel.rawText = "   "

        XCTAssertFalse(viewModel.canCapture)
    }

    func testCanCaptureIsTrueWhenTextIsNonBlank() {
        let viewModel = RecipeCaptureViewModel(captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(makeRecipe())))

        viewModel.rawText = "2 eggs\nMix well"

        XCTAssertTrue(viewModel.canCapture)
    }

    func testCaptureReturnsNilWithoutCallingUseCaseWhenTextIsBlank() async {
        let viewModel = RecipeCaptureViewModel(captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(makeRecipe())))
        viewModel.rawText = "   "

        let result = await viewModel.capture()

        XCTAssertNil(result)
    }

    func testCaptureReturnsRecipeOnSuccessAndClearsError() async {
        let recipe = makeRecipe(title: "Pancakes")
        let viewModel = RecipeCaptureViewModel(captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(recipe)))
        viewModel.rawText = "some recipe text"

        let result = await viewModel.capture()

        XCTAssertEqual(result, recipe)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isCapturing)
    }

    func testCaptureSetsErrorMessageAndReturnsNilOnFailureWithoutClearingText() async {
        let viewModel = RecipeCaptureViewModel(captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .failure(CaptureFailure())))
        viewModel.rawText = "some recipe text"

        let result = await viewModel.capture()

        XCTAssertNil(result)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.rawText, "some recipe text")
        XCTAssertFalse(viewModel.isCapturing)
    }

    private func makeRecipe(title: String = "") -> Recipe {
        Recipe(id: UUID(), title: title, ingredients: [], steps: [], source: .typed, tags: [])
    }
}
