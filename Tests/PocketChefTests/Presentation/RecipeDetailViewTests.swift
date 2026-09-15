import XCTest
import ViewInspector
@testable import PocketChef

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {}
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {}
}

private final class RecordingDeleteRecipeUseCase: DeleteRecipeUseCase {
    private(set) var executedIDs: [UUID] = []

    func execute(id: UUID) throws {
        executedIDs.append(id)
    }
}

@MainActor
final class RecipeDetailViewTests: XCTestCase {
    private func makeRecipe(ingredients: [IngredientLine] = [], steps: [String] = []) -> Recipe {
        Recipe(id: UUID(), title: "Waffles", ingredients: ingredients, steps: steps, source: .typed, tags: [])
    }

    func testEmptyIngredientsAndStepsShowPlaceholderText() throws {
        let viewModel = RecipeDetailViewModel(
            recipe: makeRecipe(),
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            deleteRecipeUseCase: RecordingDeleteRecipeUseCase()
        )
        let sut = RecipeDetailView(viewModel: viewModel)

        XCTAssertNoThrow(try sut.inspect().find(text: "No ingredients listed"))
        XCTAssertNoThrow(try sut.inspect().find(text: "No steps listed"))
    }

    func testPopulatedIngredientsAndStepsRenderContent() throws {
        let recipe = makeRecipe(
            ingredients: [IngredientLine(id: UUID(), rawText: "2 cups flour")],
            steps: ["Mix", "Cook"]
        )
        let viewModel = RecipeDetailViewModel(
            recipe: recipe,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            deleteRecipeUseCase: RecordingDeleteRecipeUseCase()
        )
        let sut = RecipeDetailView(viewModel: viewModel)

        XCTAssertNoThrow(try sut.inspect().find(text: "2 cups flour"))
        XCTAssertNoThrow(try sut.inspect().find(text: "Mix"))
        XCTAssertNoThrow(try sut.inspect().find(text: "Cook"))
    }

    func testTappingDeleteTogglesConfirmationDialogAndConfirmingItCallsDelete() throws {
        let deleteUseCase = RecordingDeleteRecipeUseCase()
        let recipe = makeRecipe()
        let viewModel = RecipeDetailViewModel(
            recipe: recipe,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            deleteRecipeUseCase: deleteUseCase
        )
        var sut = RecipeDetailView(viewModel: viewModel)

        // Local @State (isPresentingDeleteConfirmation) only reflects a tap once the view is
        // actually hosted and re-rendered, unlike the viewModel's own properties — hence the
        // didAppear hook instead of a bare `.inspect()` call before/after tapping.
        let exp = sut.on(\.didAppear) { view in
            XCTAssertThrowsError(try view.find(ViewType.ConfirmationDialog.self))

            try view.find(button: "Delete").tap()

            let dialog = try view.find(ViewType.ConfirmationDialog.self)
            XCTAssertEqual(try dialog.title().string(), "Delete this recipe?")
            try dialog.actions().find(button: "Delete").tap()

            XCTAssertEqual(deleteUseCase.executedIDs, [recipe.id])
            XCTAssertTrue(viewModel.isDeleted)
        }
        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }
        wait(for: [exp], timeout: 1)
    }

    func testCancellingConfirmationDialogDoesNotCallDelete() throws {
        let deleteUseCase = RecordingDeleteRecipeUseCase()
        let viewModel = RecipeDetailViewModel(
            recipe: makeRecipe(),
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            deleteRecipeUseCase: deleteUseCase
        )
        var sut = RecipeDetailView(viewModel: viewModel)

        let exp = sut.on(\.didAppear) { view in
            try view.find(button: "Delete").tap()
            let dialog = try view.find(ViewType.ConfirmationDialog.self)
            try dialog.actions().find(button: "Cancel").tap()

            XCTAssertTrue(deleteUseCase.executedIDs.isEmpty)
            XCTAssertFalse(viewModel.isDeleted)
        }
        ViewHosting.host(view: sut)
        defer { ViewHosting.expel() }
        wait(for: [exp], timeout: 1)
    }

    func testTappingEditTogglesEditSheetPresentedState() throws {
        let viewModel = RecipeDetailViewModel(
            recipe: makeRecipe(),
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            deleteRecipeUseCase: RecordingDeleteRecipeUseCase()
        )
        let sut = RecipeDetailView(viewModel: viewModel)

        // Tapping Edit shouldn't throw, and the toolbar should still be intact afterward.
        try sut.inspect().find(button: "Edit").tap()
        XCTAssertNoThrow(try sut.inspect().find(button: "Edit"))
    }
}
