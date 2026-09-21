@testable import PocketChef
import XCTest

private struct FakeCaptureRecipeFromURLUseCase: CaptureRecipeFromURLUseCase {
    var result: Result<Recipe, Error>

    func execute(urlString _: String) async throws -> Recipe {
        try result.get()
    }
}

private struct AICaptureFailure: Error, Equatable {}

@MainActor
final class RecipeURLCaptureViewModelTests: XCTestCase {
    func testCanCaptureIsFalseWhenURLTextIsBlankOrWhitespace() {
        let viewModel = RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .success(makeRecipe())))

        viewModel.urlText = "   "

        XCTAssertFalse(viewModel.canCapture)
    }

    func testCanCaptureIsTrueWhenURLTextIsNonBlank() {
        let viewModel = RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .success(makeRecipe())))

        viewModel.urlText = "https://example.com/recipe"

        XCTAssertTrue(viewModel.canCapture)
    }

    func testCaptureReturnsNilWithoutCallingUseCaseWhenURLTextIsBlank() async {
        let viewModel = RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .success(makeRecipe())))
        viewModel.urlText = "   "

        let result = await viewModel.capture()

        XCTAssertNil(result)
    }

    func testCaptureReturnsRecipeOnSuccessAndClearsError() async {
        let recipe = makeRecipe(title: "Pancakes")
        let viewModel = RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .success(recipe)))
        viewModel.urlText = "https://example.com/recipe"

        let result = await viewModel.capture()

        XCTAssertEqual(result, recipe)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isCapturing)
    }

    func testCaptureSetsPageLoadMessageOnWebPageFetchError() async {
        let viewModel = RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .failure(WebPageFetchError.invalidURL)))
        viewModel.urlText = "https://example.com/recipe"

        let result = await viewModel.capture()

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.errorMessage, "Couldn't load that page. Check the link and try again.")
    }

    func testCaptureSetsExtractionMessageOnNonFetchError() async {
        let viewModel = RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .failure(AICaptureFailure())))
        viewModel.urlText = "https://example.com/recipe"

        let result = await viewModel.capture()

        XCTAssertNil(result)
        XCTAssertEqual(viewModel.errorMessage, "Couldn't find a recipe on that page. Check it over and try again.")
        XCTAssertEqual(viewModel.urlText, "https://example.com/recipe")
        XCTAssertFalse(viewModel.isCapturing)
    }

    private func makeRecipe(title: String = "") -> Recipe {
        Recipe(id: UUID(), title: title, ingredients: [], steps: [], source: .typed, tags: [])
    }
}
