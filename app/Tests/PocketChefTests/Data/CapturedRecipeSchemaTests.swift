@testable import PocketChef
import XCTest

final class CapturedRecipeSchemaTests: XCTestCase {
    func testToDomainMapsFullyStructuredIngredient() {
        let schema = CapturedIngredientSchema(rawText: "2 cups flour", amount: "2", unit: "cup", ingredientName: "flour")

        let line = schema.toDomain()

        XCTAssertEqual(line.rawText, "2 cups flour")
        XCTAssertEqual(line.amount, 2)
        XCTAssertEqual(line.unit, "cup")
        XCTAssertEqual(line.ingredientName, "flour")
    }

    func testToDomainCollapsesEmptyFieldsToNilAndTrims() {
        let schema = CapturedIngredientSchema(rawText: "a pinch of salt", amount: "  ", unit: "", ingredientName: "  salt  ")

        let line = schema.toDomain()

        XCTAssertNil(line.amount)
        XCTAssertNil(line.unit)
        XCTAssertEqual(line.ingredientName, "salt")
    }

    func testToDomainLeavesAmountNilWhenUnparseable() {
        let schema = CapturedIngredientSchema(rawText: "a few eggs", amount: "a few", unit: "", ingredientName: "eggs")

        let line = schema.toDomain()

        XCTAssertNil(line.amount)
    }

    func testToDomainParsesFractionAmounts() {
        let schema = CapturedIngredientSchema(rawText: "1 1/2 tsp salt", amount: "1 1/2", unit: "tsp", ingredientName: "salt")

        XCTAssertEqual(schema.toDomain().amount, 1.5)
    }

    func testToDomainTakesUnitFromAmountWhenUnitIsEmpty() {
        let schema = CapturedIngredientSchema(rawText: "100g butter", amount: "100g", unit: "", ingredientName: "butter")

        let line = schema.toDomain()

        XCTAssertEqual(line.amount, 100)
        XCTAssertEqual(line.unit, "g")
    }

    func testToDomainPrefersExplicitUnitOverOneInAmount() {
        let schema = CapturedIngredientSchema(rawText: "100g butter", amount: "100g", unit: "grams", ingredientName: "butter")

        XCTAssertEqual(schema.toDomain().unit, "grams")
    }

    func testToDomainDropsDescriptorUsedAsUnit() {
        let schema = CapturedIngredientSchema(rawText: "1 large egg", amount: "1", unit: "large", ingredientName: "large egg")

        let line = schema.toDomain()

        XCTAssertEqual(line.amount, 1)
        XCTAssertNil(line.unit)
        XCTAssertEqual(line.ingredientName, "egg")
    }

    func testToDomainMovesIngredientFromUnitToEmptyName() {
        let schema = CapturedIngredientSchema(rawText: "1 yellow onion", amount: "1", unit: "yellow onion", ingredientName: "")

        let line = schema.toDomain()

        XCTAssertNil(line.unit)
        XCTAssertEqual(line.ingredientName, "yellow onion")
    }

    func testToDomainNeverUsesPlaceholderUnitAsName() {
        let schema = CapturedIngredientSchema(rawText: "salt & pepper to taste", amount: "", unit: "none", ingredientName: "")

        let line = schema.toDomain()

        XCTAssertNil(line.unit)
        XCTAssertNil(line.ingredientName)
    }

    func testToDomainTakesUnitFromRawTextWhenModelLeftItEmpty() {
        let schema = CapturedIngredientSchema(rawText: "1/3 cup melted butter", amount: "1/3", unit: "", ingredientName: "butter")

        let line = schema.toDomain()

        XCTAssertEqual(line.amount, 1.0 / 3)
        XCTAssertEqual(line.unit, "cup")
    }

    func testToDomainTakesUnitFromWordAmount() {
        let schema = CapturedIngredientSchema(rawText: "a pinch of salt", amount: "a pinch", unit: "", ingredientName: "salt")

        let line = schema.toDomain()

        XCTAssertNil(line.amount)
        XCTAssertEqual(line.unit, "pinch")
    }

    func testRecipeToDomainDropsIngredientsNotInSource() {
        let schema = CapturedRecipeSchema(
            title: "Crêpes",
            ingredients: [
                CapturedIngredientSchema(rawText: "250 g de farine", amount: "250", unit: "g", ingredientName: "farine"),
                CapturedIngredientSchema(rawText: "eau", amount: "", unit: "", ingredientName: "eau"),
            ],
            steps: ["Mélanger"]
        )

        let recipe = schema.toDomain(source: "Il faut 250 g de farine. Mélanger.")

        XCTAssertEqual(recipe.ingredients.map(\.rawText), ["250 g de farine"])
    }

    func testRecipeToDomainMapsFieldsAndFiltersBlankSteps() {
        let schema = CapturedRecipeSchema(
            title: "Pancakes",
            ingredients: [CapturedIngredientSchema(rawText: "1 egg", amount: "1", unit: "", ingredientName: "egg")],
            steps: ["Mix", "  ", "Cook"]
        )

        let recipe = schema.toDomain()

        XCTAssertEqual(recipe.title, "Pancakes")
        XCTAssertEqual(recipe.ingredients.count, 1)
        XCTAssertEqual(recipe.ingredients[0].ingredientName, "egg")
        XCTAssertEqual(recipe.steps, ["Mix", "Cook"])
        XCTAssertEqual(recipe.source, .typed)
        XCTAssertEqual(recipe.tags, [])
    }
}
