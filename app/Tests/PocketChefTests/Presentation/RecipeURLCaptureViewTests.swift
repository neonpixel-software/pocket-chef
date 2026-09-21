@testable import PocketChef
import ViewInspector
import XCTest

private struct FakeCaptureRecipeFromURLUseCase: CaptureRecipeFromURLUseCase {
    var result: Result<Recipe, Error>

    func execute(urlString _: String) async throws -> Recipe {
        try result.get()
    }
}

private struct CaptureFailure: Error, Equatable {}

@MainActor
final class RecipeURLCaptureViewTests: XCTestCase {
    func testCaptureButtonDisabledWhenURLTextBlankEnabledWhenSet() throws {
        let viewModel = makeViewModel()
        let sut = RecipeURLCaptureView(viewModel: viewModel, onCaptured: { _ in })

        let disabledCapture = try sut.inspect().find(button: "Capture")
        XCTAssertTrue(disabledCapture.isDisabled())

        viewModel.urlText = "https://example.com/recipe"
        let enabledCapture = try sut.inspect().find(button: "Capture")
        XCTAssertFalse(enabledCapture.isDisabled())
    }

    func testCancelButtonExistsAndIsEnabledByDefault() throws {
        let viewModel = makeViewModel()
        let sut = RecipeURLCaptureView(viewModel: viewModel, onCaptured: { _ in })

        let cancelButton = try sut.inspect().find(button: "Cancel")
        XCTAssertFalse(cancelButton.isDisabled())
    }

    func testTappingCaptureWithBlankURLIsRefusedAsDisabled() throws {
        let viewModel = makeViewModel()
        nonisolated(unsafe) var capturedRecipe: Recipe?
        let sut = RecipeURLCaptureView(viewModel: viewModel, onCaptured: { capturedRecipe = $0 })

        XCTAssertThrowsError(try sut.inspect().find(button: "Capture").tap())
        XCTAssertNil(capturedRecipe)
    }

    func testErrorMessageDisplaysAfterAFailedCapture() async throws {
        let viewModel = RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .failure(CaptureFailure())))
        viewModel.urlText = "https://example.com/recipe"
        _ = await viewModel.capture()
        let sut = RecipeURLCaptureView(viewModel: viewModel, onCaptured: { _ in })

        XCTAssertNoThrow(try sut.inspect().find(text: viewModel.errorMessage ?? ""))
    }

    private func makeViewModel() -> RecipeURLCaptureViewModel {
        RecipeURLCaptureViewModel(captureRecipeFromURLUseCase: FakeCaptureRecipeFromURLUseCase(result: .success(
            Recipe(id: UUID(), title: "", ingredients: [], steps: [], source: .typed, tags: [])
        )))
    }
}
