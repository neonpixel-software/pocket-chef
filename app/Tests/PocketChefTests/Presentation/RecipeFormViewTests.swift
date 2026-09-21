@testable import PocketChef
import ViewInspector
import XCTest

private final class RecordingCreateRecipeUseCase: CreateRecipeUseCase {
    var result: Result<Void, Error> = .success(())
    func execute(_: Recipe) throws { try result.get() }
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_: Recipe) throws {}
}

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_: Recipe) throws {}
}

private struct FakeFetchTagsUseCase: FetchTagsUseCase {
    var result: Result<[Tag], Error> = .success([])
    func execute() throws -> [Tag] { try result.get() }
}

private final class FakeFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    var resultProvider: (String) -> Result<Tag, Error> = { name in .success(Tag(id: UUID(), name: name, isPreset: false)) }
    func execute(name: String) throws -> Tag { try resultProvider(name).get() }
}

private struct UseCaseFailure: LocalizedError {
    var errorDescription: String? { "Something went wrong" }
}

private func makeViewModel(
    mode: RecipeFormMode = .create,
    createUseCase: CreateRecipeUseCase = NoOpCreateRecipeUseCase(),
    updateUseCase: UpdateRecipeUseCase = NoOpUpdateRecipeUseCase(),
    fetchTagsUseCase: FetchTagsUseCase = FakeFetchTagsUseCase(),
    findOrCreateTagUseCase: FindOrCreateTagUseCase = FakeFindOrCreateTagUseCase()
) -> RecipeFormViewModel {
    RecipeFormViewModel(
        mode: mode,
        createRecipeUseCase: createUseCase,
        updateRecipeUseCase: updateUseCase,
        fetchTagsUseCase: fetchTagsUseCase,
        findOrCreateTagUseCase: findOrCreateTagUseCase
    )
}

@MainActor
final class RecipeFormViewTests: XCTestCase {
    func testSaveButtonDisabledWhenTitleBlankEnabledWhenSet() throws {
        let viewModel = makeViewModel()
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        let disabledSave = try sut.inspect().find(button: "Save")
        XCTAssertTrue(disabledSave.isDisabled())

        viewModel.title = "Waffles"
        let enabledSave = try sut.inspect().find(button: "Save")
        XCTAssertFalse(enabledSave.isDisabled())
    }

    func testTappingSaveCallsOnSaveWithComposedRecipeAndDoesNotErrorOnSuccess() throws {
        let viewModel = makeViewModel()
        viewModel.title = "Waffles"
        nonisolated(unsafe) var saved: Recipe?
        let sut = RecipeFormView(viewModel: viewModel, onSave: { saved = $0 })

        try sut.inspect().find(button: "Save").tap()

        XCTAssertEqual(saved?.title, "Waffles")
        XCTAssertThrowsError(try sut.inspect().find(text: "Something went wrong"))
    }

    func testTappingCancelDoesNotCallOnSave() throws {
        let viewModel = makeViewModel()
        viewModel.title = "Waffles"
        nonisolated(unsafe) var saveCalled = false
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in saveCalled = true })

        try sut.inspect().find(button: "Cancel").tap()

        XCTAssertFalse(saveCalled)
    }

    func testSaveFailureDisplaysErrorMessage() throws {
        let createUseCase = RecordingCreateRecipeUseCase()
        createUseCase.result = .failure(UseCaseFailure())
        let viewModel = makeViewModel(createUseCase: createUseCase)
        viewModel.title = "Waffles"
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        try sut.inspect().find(button: "Save").tap()

        let errorText = try sut.inspect().find(text: "Something went wrong")
        XCTAssertEqual(try errorText.string(), "Something went wrong")
    }

    func testAddIngredientButtonAddsRow() throws {
        let viewModel = makeViewModel()
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        XCTAssertEqual(viewModel.ingredients.count, 0)
        try sut.inspect().find(button: "Add Ingredient").tap()
        XCTAssertEqual(viewModel.ingredients.count, 1)
    }

    func testAddStepButtonAddsRow() throws {
        let viewModel = makeViewModel()
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        XCTAssertEqual(viewModel.steps.count, 0)
        try sut.inspect().find(button: "Add Step").tap()
        XCTAssertEqual(viewModel.steps.count, 1)
    }

    func testIngredientRowControlsMoveAndDelete() throws {
        let viewModel = makeViewModel()
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
        let viewModel = makeViewModel()
        viewModel.addStep()
        viewModel.addStep()
        viewModel.steps[0].text = "Mix"
        viewModel.steps[1].text = "Cook"
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        let moveDownButtons = try sut.inspect().findAll(where: { try $0.accessibilityLabel().string() == "Move down" })
        XCTAssertEqual(moveDownButtons.count, 2)
        try moveDownButtons[0].button().tap()
        XCTAssertEqual(viewModel.steps.map(\.text), ["Cook", "Mix"])

        let deleteButtons = try sut.inspect().findAll(where: { try $0.accessibilityLabel().string() == "Delete" })
        try deleteButtons[1].button().tap()
        XCTAssertEqual(viewModel.steps.map(\.text), ["Cook"])
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
        let viewModel = makeViewModel(mode: .edit(original))
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        // Rendering the fully-populated edit form shouldn't throw, and the Save
        // button should already be enabled since the pre-filled title is non-blank.
        let saveButton = try sut.inspect().find(button: "Save")
        XCTAssertFalse(saveButton.isDisabled())
    }

    // MARK: tags

    func testTappingATagChipTogglesItsSelection() throws {
        let breakfast = Tag(id: UUID(), name: "Breakfast", isPreset: true)
        let viewModel = makeViewModel(fetchTagsUseCase: FakeFetchTagsUseCase(result: .success([breakfast])))
        viewModel.loadTags() // .task doesn't run without real hosting; call directly
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        XCTAssertFalse(viewModel.selectedTagIDs.contains(breakfast.id))
        try sut.inspect().find(button: "Breakfast").tap()
        XCTAssertTrue(viewModel.selectedTagIDs.contains(breakfast.id))
    }

    func testNewTagChipSwapsToTextFieldAndConfirmingAddsASelectedTag() throws {
        let viewModel = makeViewModel()
        viewModel.loadTags()
        let sut = RecipeFormView(viewModel: viewModel, onSave: { _ in })

        try sut.inspect().find(button: "+ New Tag").tap()
        XCTAssertTrue(viewModel.isAddingNewTag)

        viewModel.newTagName = "Spicy"
        viewModel.confirmNewTag()

        XCTAssertEqual(viewModel.allTags.map(\.name), ["Spicy"])
        XCTAssertTrue(viewModel.selectedTagIDs.contains(viewModel.allTags[0].id))
    }
}
