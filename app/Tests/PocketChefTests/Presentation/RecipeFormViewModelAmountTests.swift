@testable import PocketChef
import XCTest

private struct NoOpCreateRecipeUseCase: CreateRecipeUseCase {
    func execute(_: Recipe) throws {}
}

private struct NoOpUpdateRecipeUseCase: UpdateRecipeUseCase {
    func execute(_: Recipe) throws {}
}

private struct NoOpFetchTagsUseCase: FetchTagsUseCase {
    func execute() throws -> [Tag] { [] }
}

private struct NoOpFindOrCreateTagUseCase: FindOrCreateTagUseCase {
    func execute(name: String) throws -> Tag {
        Tag(id: UUID(), name: name, isPreset: false)
    }
}

/// Fractional amounts on the form, and keeping an untouched line's wording (issue #87).
final class RecipeFormViewModelAmountTests: XCTestCase {
    func testCaptureModeShowsAThirdsAmountReadablyAndSavesTheOriginalWordingUntouched() throws {
        let line = IngredientLine(
            id: UUID(), rawText: "1 ⅔ cups all-purpose flour",
            amount: 5.0 / 3, unit: "cups", ingredientName: "all-purpose flour"
        )
        let captured = Recipe(id: UUID(), title: "Cake", ingredients: [line], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(mode: .capture(captured))

        XCTAssertEqual(viewModel.ingredients.first?.amount, "1⅔")

        let recipe = try XCTUnwrap(viewModel.save())
        XCTAssertEqual(recipe.ingredients, [line])
    }

    func testSaveKeepsOriginalWordingTheStructuredFieldsCannotExpress() throws {
        let line = IngredientLine(
            id: UUID(), rawText: "1 cup plus 2 tablespoons sugar",
            amount: 1, unit: "cup", ingredientName: "sugar"
        )
        let original = Recipe(id: UUID(), title: "Cake", ingredients: [line], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(mode: .edit(original))

        let recipe = try XCTUnwrap(viewModel.save())

        XCTAssertEqual(recipe.ingredients[0].rawText, "1 cup plus 2 tablespoons sugar")
    }

    func testEditingARowsAmountToATypedFractionSavesItsValueAndRebuildsTheWording() throws {
        let line = IngredientLine(
            id: UUID(), rawText: "1 ⅔ cups all-purpose flour",
            amount: 5.0 / 3, unit: "cups", ingredientName: "all-purpose flour"
        )
        let original = Recipe(id: UUID(), title: "Cake", ingredients: [line], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(mode: .edit(original))

        viewModel.ingredients[0].amount = "1 1/2"
        let recipe = try XCTUnwrap(viewModel.save())

        XCTAssertEqual(recipe.ingredients[0].amount, 1.5)
        XCTAssertEqual(recipe.ingredients[0].rawText, "1 1/2 cups all-purpose flour")
        XCTAssertEqual(IngredientLineDraft(ingredientLine: recipe.ingredients[0]).amount, "1½")
    }

    func testEditingOnlyTheNameRebuildsTheWordingButKeepsTheParsedAmount() throws {
        let line = IngredientLine(
            id: UUID(), rawText: "⅓ cup sugar",
            amount: 1.0 / 3, unit: "cup", ingredientName: "sugar"
        )
        let original = Recipe(id: UUID(), title: "Cake", ingredients: [line], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(mode: .edit(original))

        viewModel.ingredients[0].ingredientName = "brown sugar"
        let recipe = try XCTUnwrap(viewModel.save())

        XCTAssertEqual(recipe.ingredients[0].rawText, "⅓ cup brown sugar")
        XCTAssertEqual(try XCTUnwrap(recipe.ingredients[0].amount), 1.0 / 3, accuracy: 1e-9)
    }

    func testEditingOnlyTheNameKeepsAnAmountTheFieldShowsRounded() throws {
        let line = IngredientLine(id: UUID(), rawText: "0.333 cup sugar", amount: 0.333, unit: "cup", ingredientName: "sugar")
        let original = Recipe(id: UUID(), title: "Cake", ingredients: [line], steps: [], source: .typed, tags: [])
        let viewModel = makeViewModel(mode: .edit(original))
        XCTAssertEqual(viewModel.ingredients[0].amount, "0.33")

        viewModel.ingredients[0].ingredientName = "brown sugar"
        let recipe = try XCTUnwrap(viewModel.save())

        XCTAssertEqual(recipe.ingredients[0].amount, 0.333)
    }

    func testSaveParsesAmountsTypedAsVulgarOrCommaDecimals() throws {
        let viewModel = makeViewModel(mode: .create)
        viewModel.title = "Soup"
        for amount in ["1½", "2,5"] {
            viewModel.addIngredient()
            viewModel.ingredients[viewModel.ingredients.count - 1].amount = amount
            viewModel.ingredients[viewModel.ingredients.count - 1].ingredientName = "stock"
        }

        let recipe = try XCTUnwrap(viewModel.save())

        XCTAssertEqual(recipe.ingredients.map(\.amount), [1.5, 2.5])
    }

    private func makeViewModel(mode: RecipeFormMode) -> RecipeFormViewModel {
        RecipeFormViewModel(
            mode: mode,
            createRecipeUseCase: NoOpCreateRecipeUseCase(),
            updateRecipeUseCase: NoOpUpdateRecipeUseCase(),
            fetchTagsUseCase: NoOpFetchTagsUseCase(),
            findOrCreateTagUseCase: NoOpFindOrCreateTagUseCase()
        )
    }
}
