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
