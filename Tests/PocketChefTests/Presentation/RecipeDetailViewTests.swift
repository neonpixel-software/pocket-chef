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

private struct NoOpFetchTagsUseCase: FetchTagsUseCase {
    func execute() throws -> [Tag] { [] }
}

private struct NoOpFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

private func makeViewModel(
    recipe: Recipe,
    deleteRecipeUseCase: DeleteRecipeUseCase = RecordingDeleteRecipeUseCase()
) -> RecipeDetailViewModel {
    RecipeDetailViewModel(
        recipe: recipe,
        createRecipeUseCase: NoOpCreateRecipeUseCase(),
        updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
        deleteRecipeUseCase: deleteRecipeUseCase,
        fetchTagsUseCase: NoOpFetchTagsUseCase(),
        findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase()
    )
}

@MainActor
final class RecipeDetailViewTests: XCTestCase {
    private func makeRecipe(ingredients: [IngredientLine] = [], steps: [String] = [], tags: [Tag] = []) -> Recipe {
        Recipe(id: UUID(), title: "Waffles", ingredients: ingredients, steps: steps, source: .typed, tags: tags)
    }

    func testEmptyIngredientsAndStepsShowPlaceholderText() throws {
        let viewModel = makeViewModel(recipe: makeRecipe())
        let sut = RecipeDetailView(viewModel: viewModel)

        XCTAssertNoThrow(try sut.inspect().find(text: "No ingredients listed"))
        XCTAssertNoThrow(try sut.inspect().find(text: "No steps listed"))
    }

    func testPopulatedIngredientsAndStepsRenderContent() throws {
        let recipe = makeRecipe(
            ingredients: [IngredientLine(id: UUID(), rawText: "2 cups flour")],
            steps: ["Mix", "Cook"]
        )
        let viewModel = makeViewModel(recipe: recipe)
        let sut = RecipeDetailView(viewModel: viewModel)

        XCTAssertNoThrow(try sut.inspect().find(text: "2 cups flour"))
        XCTAssertNoThrow(try sut.inspect().find(text: "Mix"))
        XCTAssertNoThrow(try sut.inspect().find(text: "Cook"))
    }

    func testAssignedTagsRenderAsChips() throws {
        let breakfast = Tag(id: UUID(), name: "Breakfast", isPreset: true)
        let recipe = makeRecipe(tags: [breakfast])
        let viewModel = makeViewModel(recipe: recipe)
        let sut = RecipeDetailView(viewModel: viewModel)

        XCTAssertNoThrow(try sut.inspect().find(text: "Breakfast"))
    }

    func testTappingDeleteTogglesConfirmationDialogAndConfirmingItCallsDelete() throws {
        let deleteUseCase = RecordingDeleteRecipeUseCase()
        let recipe = makeRecipe()
        let viewModel = makeViewModel(recipe: recipe, deleteRecipeUseCase: deleteUseCase)
        let sut = RecipeDetailView(viewModel: viewModel)

        XCTAssertThrowsError(try sut.inspect().find(ViewType.ConfirmationDialog.self))

        try sut.inspect().find(button: "Delete").tap()
        XCTAssertTrue(viewModel.isPresentingDeleteConfirmation)

        let dialog = try sut.inspect().find(ViewType.ConfirmationDialog.self)
        XCTAssertEqual(try dialog.title().string(), "Delete this recipe?")
        try dialog.actions().find(button: "Delete").tap()

        XCTAssertEqual(deleteUseCase.executedIDs, [recipe.id])
        XCTAssertTrue(viewModel.isDeleted)
    }

    func testCancellingConfirmationDialogDoesNotCallDelete() throws {
        let deleteUseCase = RecordingDeleteRecipeUseCase()
        let viewModel = makeViewModel(recipe: makeRecipe(), deleteRecipeUseCase: deleteUseCase)
        let sut = RecipeDetailView(viewModel: viewModel)

        try sut.inspect().find(button: "Delete").tap()
        let dialog = try sut.inspect().find(ViewType.ConfirmationDialog.self)
        try dialog.actions().find(button: "Cancel").tap()

        XCTAssertTrue(deleteUseCase.executedIDs.isEmpty)
        XCTAssertFalse(viewModel.isDeleted)
    }

    func testTappingEditSetsPresentingEditOnViewModel() throws {
        let viewModel = makeViewModel(recipe: makeRecipe())
        let sut = RecipeDetailView(viewModel: viewModel)

        XCTAssertFalse(viewModel.isPresentingEdit)
        try sut.inspect().find(button: "Edit").tap()
        XCTAssertTrue(viewModel.isPresentingEdit)
    }
}
