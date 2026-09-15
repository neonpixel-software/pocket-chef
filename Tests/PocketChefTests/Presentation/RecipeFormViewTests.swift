import XCTest
import ViewInspector
@testable import PocketChef

private final class RecordingCreateRecipeUseCase: CreateRecipeUseCase {
    var result: Result<Void, Error> = .success(())
    func execute(_ recipe: Recipe) throws { try result.get() }
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {}
}

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_ recipe: Recipe) throws {}
}

private struct UseCaseFailure: LocalizedError {
    var errorDescription: String? { "Something went wrong" }
}

@MainActor
final class RecipeFormViewTests: XCTestCase {
    func testSaveButtonDisabledWhenTitleBlankEnabledWhenSet() throws {
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        let disabledSave = try sut.inspect().find(button: "Save")
        XCTAssertTrue(disabledSave.isDisabled())

        viewModel.title = "Waffles"
        let enabledSave = try sut.inspect().find(button: "Save")
        XCTAssertFalse(enabledSave.isDisabled())
    }

    func testTappingSaveCallsOnSaveWithComposedRecipeAndDoesNotErrorOnSuccess() throws {
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        viewModel.title = "Waffles"
        nonisolated(unsafe) var saved: Recipe?
        let sut = RecipeFormView(viewModel: viewModel, onSave: { saved = $0 })

        try sut.inspect().find(button: "Save").tap()

        XCTAssertEqual(saved?.title, "Waffles")
        XCTAssertThrowsError(try sut.inspect().find(text: "Something went wrong"))
    }

    func testTappingCancelDoesNotCallOnSave() throws {
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        viewModel.title = "Waffles"
        nonisolated(unsafe) var saveCalled = false
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in saveCalled = true })

        try sut.inspect().find(button: "Cancel").tap()

        XCTAssertFalse(saveCalled)
    }

    func testSaveFailureDisplaysErrorMessage() throws {
        let createUseCase = RecordingCreateRecipeUseCase()
        createUseCase.result = .failure(UseCaseFailure())
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: createUseCase,
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        viewModel.title = "Waffles"
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        try sut.inspect().find(button: "Save").tap()

        let errorText = try sut.inspect().find(text: "Something went wrong")
        XCTAssertEqual(try errorText.string(), "Something went wrong")
    }

    func testAddIngredientButtonAddsRow() throws {
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        XCTAssertEqual(viewModel.ingredients.count, 0)
        try sut.inspect().find(button: "Add Ingredient").tap()
        XCTAssertEqual(viewModel.ingredients.count, 1)
    }

    func testAddStepButtonAddsRow() throws {
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        XCTAssertEqual(viewModel.steps.count, 0)
        try sut.inspect().find(button: "Add Step").tap()
        XCTAssertEqual(viewModel.steps.count, 1)
    }

    func testIngredientRowControlsMoveAndDelete() throws {
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        viewModel.addIngredient()
        viewModel.addIngredient()
        let firstID = viewModel.ingredients[0].id
        let secondID = viewModel.ingredients[1].id
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        // The second row's "Move up" swaps it with the first.
        let moveUpButtons = try sut.inspect().findAll(where: { try $0.accessibilityLabel().string() == "Move up" })
        XCTAssertEqual(moveUpButtons.count, 2)
        try moveUpButtons[1].button().tap()
        XCTAssertEqual(viewModel.ingredients.map(\.id), [secondID, firstID])

        let deleteButtons = try sut.inspect().findAll(where: { try $0.accessibilityLabel().string() == "Delete" })
        try deleteButtons[0].button().tap()
        XCTAssertEqual(viewModel.ingredients.map(\.id), [firstID])
    }

    func testStepRowControlsMoveAndDelete() throws {
        let viewModel = RecipeFormViewModel(
            mode: .create,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        viewModel.addStep()
        viewModel.addStep()
        viewModel.steps[0] = "Mix"
        viewModel.steps[1] = "Cook"
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        let moveDownButtons = try sut.inspect().findAll(where: { try $0.accessibilityLabel().string() == "Move down" })
        XCTAssertEqual(moveDownButtons.count, 2)
        try moveDownButtons[0].button().tap()
        XCTAssertEqual(viewModel.steps, ["Cook", "Mix"])

        let deleteButtons = try sut.inspect().findAll(where: { try $0.accessibilityLabel().string() == "Delete" })
        try deleteButtons[1].button().tap()
        XCTAssertEqual(viewModel.steps, ["Cook"])
    }

    func testEditModeRendersPrefilledTitleIngredientsAndSteps() throws {
        let original = Recipe(
            id: UUID(),
            title: "Pancakes",
            ingredients: [IngredientLine(id: UUID(), rawText: "2 cups flour", amount: 2, unit: "cup", ingredientName: "flour")],
            steps: ["Mix", "Cook"],
            source: .typed,
            tags: []
        )
        let viewModel = RecipeFormViewModel(
            mode: .edit(original),
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase()
        )
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        // Rendering the fully-populated edit form shouldn't throw, and the Save
        // button should already be enabled since the pre-filled title is non-blank.
        let saveButton = try sut.inspect().find(button: "Save")
        XCTAssertFalse(saveButton.isDisabled())
    }
}
