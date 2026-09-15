import XCTest
@testable import PocketChef

private final class FakeCreateRecipeUseCase: CreateRecipeUseCase {
    var result: Result<Void, Error> = .success(())
    private(set) var createdRecipes: [Recipe] = []

    func execute(_ recipe: Recipe) throws {
        createdRecipes.append(recipe)
        try result.get()
    }
}

private final class FakeUpdateRecipeUseCase: UpdateRecipeUseCase {
    var result: Result<Void, Error> = .success(())
    private(set) var updatedRecipes: [Recipe] = []

    func execute(_ recipe: Recipe) throws {
        updatedRecipes.append(recipe)
        try result.get()
    }
}

private struct UseCaseFailure: LocalizedError {
    var errorDescription: String? { "Something went wrong" }
}

final class RecipeFormViewModelTests: XCTestCase {
    // MARK: canSave

    func testCanSaveIsFalseWhenTitleIsBlankOrWhitespace() {
        let viewModel = makeViewModel(mode: .create)

        viewModel.title = "   "

        XCTAssertFalse(viewModel.canSave)
    }

    func testCanSaveIsTrueWhenTitleIsNonBlank() {
        let viewModel = makeViewModel(mode: .create)

        viewModel.title = "Pancakes"

        XCTAssertTrue(viewModel.canSave)
    }

    // MARK: edit mode pre-fill

    func testEditModePrefillsFieldsFromOriginalRecipe() {
        let original = Recipe(
            id: UUID(),
            title: "Pancakes",
            ingredients: [IngredientLine(id: UUID(), rawText: "2 cups flour", amount: 2, unit: "cup", ingredientName: "flour")],
            steps: ["Mix", "Cook"],
            source: .typed,
            tags: [Tag(id: UUID(), name: "Breakfast", isPreset: true)]
        )

        let viewModel = makeViewModel(mode: .edit(original))

        XCTAssertEqual(viewModel.title, "Pancakes")
        XCTAssertEqual(viewModel.steps, ["Mix", "Cook"])
        XCTAssertEqual(viewModel.ingredients.first?.amount, "2")
        XCTAssertEqual(viewModel.ingredients.first?.unit, "cup")
        XCTAssertEqual(viewModel.ingredients.first?.ingredientName, "flour")
    }

    func testEditModeFormatsFractionalAmountWithoutTrailingZero() {
        let original = Recipe(
            id: UUID(),
            title: "Pancakes",
            ingredients: [IngredientLine(id: UUID(), rawText: "1.5 cups flour", amount: 1.5, unit: "cup", ingredientName: "flour")],
            steps: [],
            source: .typed,
            tags: []
        )

        let viewModel = makeViewModel(mode: .edit(original))

        XCTAssertEqual(viewModel.ingredients.first?.amount, "1.5")
    }

    func testSaveInEditModePreservesRawOnlyIngredientLineUntouchedByStructuredFields() throws {
        let original = Recipe(
            id: UUID(),
            title: "Pancakes",
            ingredients: [IngredientLine(id: UUID(), rawText: "1 egg")],
            steps: [],
            source: .typed,
            tags: []
        )
        let updateUseCase = FakeUpdateRecipeUseCase()
        let viewModel = makeViewModel(mode: .edit(original), updateUseCase: updateUseCase)

        let saved = viewModel.save()

        let recipe = try XCTUnwrap(saved)
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.ingredients[0].rawText, "1 egg")
        XCTAssertNil(recipe.ingredients[0].amount)
    }

    // MARK: ingredient mutation

    func testAddRemoveMoveIngredient() {
        let viewModel = makeViewModel(mode: .create)

        viewModel.addIngredient()
        viewModel.addIngredient()
        XCTAssertEqual(viewModel.ingredients.count, 2)

        let firstID = viewModel.ingredients[0].id
        let secondID = viewModel.ingredients[1].id

        viewModel.moveIngredientDown(at: 0)
        XCTAssertEqual(viewModel.ingredients.map(\.id), [secondID, firstID])

        viewModel.moveIngredientUp(at: 1)
        XCTAssertEqual(viewModel.ingredients.map(\.id), [firstID, secondID])

        viewModel.removeIngredient(at: 0)
        XCTAssertEqual(viewModel.ingredients.map(\.id), [secondID])
    }

    func testMoveIngredientIsNoOpAtBoundaries() {
        let viewModel = makeViewModel(mode: .create)
        viewModel.addIngredient()
        let onlyID = viewModel.ingredients[0].id

        viewModel.moveIngredientUp(at: 0)
        viewModel.moveIngredientDown(at: 0)

        XCTAssertEqual(viewModel.ingredients.map(\.id), [onlyID])
    }

    // MARK: step mutation

    func testAddRemoveMoveStep() {
        let viewModel = makeViewModel(mode: .create)

        viewModel.addStep()
        viewModel.steps[0] = "Mix"
        viewModel.addStep()
        viewModel.steps[1] = "Cook"

        viewModel.moveStepDown(at: 0)
        XCTAssertEqual(viewModel.steps, ["Cook", "Mix"])

        viewModel.moveStepUp(at: 1)
        XCTAssertEqual(viewModel.steps, ["Mix", "Cook"])

        viewModel.removeStep(at: 0)
        XCTAssertEqual(viewModel.steps, ["Cook"])
    }

    // MARK: save — create

    func testSaveInCreateModeBuildsRecipeWithComposedRawTextAndCallsCreateUseCase() throws {
        let createUseCase = FakeCreateRecipeUseCase()
        let viewModel = makeViewModel(mode: .create, createUseCase: createUseCase)
        viewModel.title = "  Pancakes  "
        viewModel.addIngredient()
        viewModel.ingredients[0].amount = "2"
        viewModel.ingredients[0].unit = "cups"
        viewModel.ingredients[0].ingredientName = "flour"
        viewModel.addStep()
        viewModel.steps[0] = "  Mix well  "

        let saved = viewModel.save()

        let recipe = try XCTUnwrap(saved)
        XCTAssertEqual(recipe.title, "Pancakes")
        XCTAssertEqual(recipe.steps, ["Mix well"])
        XCTAssertEqual(recipe.source, .typed)
        XCTAssertEqual(recipe.tags, [])
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.ingredients[0].rawText, "2 cups flour")
        XCTAssertEqual(recipe.ingredients[0].amount, 2)
        XCTAssertEqual(createUseCase.createdRecipes, [recipe])
    }

    func testSaveSkipsFullyBlankIngredientRowsAndStepsAndParsesUnparseableAmountAsNil() throws {
        let createUseCase = FakeCreateRecipeUseCase()
        let viewModel = makeViewModel(mode: .create, createUseCase: createUseCase)
        viewModel.title = "Soup"
        viewModel.addIngredient() // fully blank, should be dropped
        viewModel.addIngredient()
        viewModel.ingredients[1].ingredientName = "salt" // only name filled
        viewModel.addStep() // blank, should be dropped
        viewModel.addStep()
        viewModel.steps[1] = "Simmer"

        let saved = viewModel.save()

        let recipe = try XCTUnwrap(saved)
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.ingredients[0].rawText, "salt")
        XCTAssertNil(recipe.ingredients[0].amount)
        XCTAssertEqual(recipe.steps, ["Simmer"])
    }

    func testSaveReturnsNilAndDoesNotCallUseCaseWhenTitleIsBlank() {
        let createUseCase = FakeCreateRecipeUseCase()
        let viewModel = makeViewModel(mode: .create, createUseCase: createUseCase)
        viewModel.title = "   "

        let saved = viewModel.save()

        XCTAssertNil(saved)
        XCTAssertTrue(createUseCase.createdRecipes.isEmpty)
    }

    func testSaveSetsErrorMessageAndReturnsNilOnCreateFailure() {
        let createUseCase = FakeCreateRecipeUseCase()
        createUseCase.result = .failure(UseCaseFailure())
        let viewModel = makeViewModel(mode: .create, createUseCase: createUseCase)
        viewModel.title = "Pancakes"

        let saved = viewModel.save()

        XCTAssertNil(saved)
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong")
    }

    // MARK: save — edit

    func testSaveInEditModePreservesOriginalIdentitySourceAndTagsAndCallsUpdateUseCase() throws {
        let originalID = UUID()
        let tag = Tag(id: UUID(), name: "Breakfast", isPreset: true)
        let original = Recipe(id: originalID, title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [tag])
        let updateUseCase = FakeUpdateRecipeUseCase()
        let viewModel = makeViewModel(mode: .edit(original), updateUseCase: updateUseCase)
        viewModel.title = "Fluffy Pancakes"

        let saved = viewModel.save()

        let recipe = try XCTUnwrap(saved)
        XCTAssertEqual(recipe.id, originalID)
        XCTAssertEqual(recipe.title, "Fluffy Pancakes")
        XCTAssertEqual(recipe.source, .typed)
        XCTAssertEqual(recipe.tags, [tag])
        XCTAssertEqual(updateUseCase.updatedRecipes, [recipe])
    }

    func testSaveSetsErrorMessageAndReturnsNilOnUpdateFailure() {
        let original = Recipe(id: UUID(), title: "Pancakes", ingredients: [], steps: [], source: .typed, tags: [])
        let updateUseCase = FakeUpdateRecipeUseCase()
        updateUseCase.result = .failure(UseCaseFailure())
        let viewModel = makeViewModel(mode: .edit(original), updateUseCase: updateUseCase)

        let saved = viewModel.save()

        XCTAssertNil(saved)
        XCTAssertEqual(viewModel.errorMessage, "Something went wrong")
    }

    // MARK: helpers

    private func makeViewModel(
        mode: RecipeFormMode,
        createUseCase: FakeCreateRecipeUseCase = FakeCreateRecipeUseCase(),
        updateUseCase: FakeUpdateRecipeUseCase = FakeUpdateRecipeUseCase()
    ) -> RecipeFormViewModel {
        RecipeFormViewModel(mode: mode, createRecipeUseCase: createUseCase, updateRecipeUseCase: updateUseCase)
    }
}
