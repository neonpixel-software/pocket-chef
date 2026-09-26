@testable import PocketChef
import SwiftUI
import ViewInspector
import XCTest

private struct FakeCaptureRecipeUseCase: CaptureRecipeUseCase {
    var result: Result<Recipe, Error>

    func execute(text _: String) async throws -> Recipe {
        try result.get()
    }
}

private struct CaptureFailure: Error, Equatable {}

@MainActor
final class RecipeCaptureViewTests: XCTestCase {
    func testCaptureButtonDisabledWhenTextBlankEnabledWhenSet() throws {
        let viewModel = makeViewModel()
        let sut = RecipeCaptureView(viewModel: viewModel, onCaptured: { _ in })

        let disabledCapture = try sut.inspect().find(button: "Capture")
        XCTAssertTrue(disabledCapture.isDisabled())

        viewModel.rawText = "2 eggs\nMix well"
        let enabledCapture = try sut.inspect().find(button: "Capture")
        XCTAssertFalse(enabledCapture.isDisabled())
    }

    func testCancelButtonExistsAndIsEnabledByDefault() throws {
        let viewModel = makeViewModel()
        let sut = RecipeCaptureView(viewModel: viewModel, onCaptured: { _ in })

        let cancelButton = try sut.inspect().find(button: "Cancel")
        XCTAssertFalse(cancelButton.isDisabled())
    }

    func testTappingCaptureWithBlankTextIsRefusedAsDisabled() throws {
        let viewModel = makeViewModel()
        nonisolated(unsafe) var capturedRecipe: Recipe?
        let sut = RecipeCaptureView(viewModel: viewModel, onCaptured: { capturedRecipe = $0 })

        XCTAssertThrowsError(try sut.inspect().find(button: "Capture").tap())
        XCTAssertNil(capturedRecipe)
    }

    func testErrorMessageDisplaysAfterAFailedCapture() async throws {
        let viewModel = RecipeCaptureViewModel(captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .failure(CaptureFailure())))
        viewModel.rawText = "some recipe text"
        _ = await viewModel.capture()
        let sut = RecipeCaptureView(viewModel: viewModel, onCaptured: { _ in })

        XCTAssertNoThrow(try sut.inspect().find(text: viewModel.errorMessage ?? ""))
    }

    /// Regression guard for #89: the list builds the view model inside a `.sheet` closure, which runs
    /// again on every list re-render. The view must own the first instance (@State); with
    /// @Bindable it switched to the new one and lost its state.
    func testCaptureViewOwnsItsViewModelAsState() {
        let sut = RecipeCaptureView(viewModel: makeViewModel(), onCaptured: { _ in })
        let storage = Mirror(reflecting: sut).children.first { $0.label == "_viewModel" }?.value
        XCTAssertTrue(storage is State<RecipeCaptureViewModel>)
    }

    private func makeViewModel() -> RecipeCaptureViewModel {
        RecipeCaptureViewModel(captureRecipeUseCase: FakeCaptureRecipeUseCase(result: .success(
            Recipe(id: UUID(), title: "", ingredients: [], steps: [], source: .typed, tags: [])
        )))
    }
}
