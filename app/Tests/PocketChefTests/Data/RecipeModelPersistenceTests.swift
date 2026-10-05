@testable import PocketChef
import SwiftData
import XCTest

final class RecipeModelPersistenceTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            RecipeModel.self,
            IngredientLineModel.self,
            TagModel.self,
            DensityEntryModel.self,
        ])
        let container = try ModelContainer.inMemory(schema: schema)
        return ModelContext(container)
    }

    func testRecipeWithIngredientsAndTagsPersistsAndFetches() throws {
        let context = try makeInMemoryContext()

        let ingredient = IngredientLineModel(
            rawText: "2 cups flour",
            amount: 2,
            unit: "cup",
            ingredientName: "flour"
        )
        let tag = TagModel(name: "Breakfast", isPreset: true)
        let recipe = RecipeModel(
            title: "Pancakes",
            steps: ["Mix dry ingredients", "Cook on griddle"],
            isTypedSource: true,
            ingredients: [ingredient],
            tags: [tag]
        )

        context.insert(recipe)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<RecipeModel>())

        XCTAssertEqual(fetched.count, 1)
        let fetchedRecipe = try XCTUnwrap(fetched.first)
        XCTAssertEqual(fetchedRecipe.title, "Pancakes")
        XCTAssertEqual(fetchedRecipe.ingredients?.count, 1)
        XCTAssertEqual(fetchedRecipe.ingredients?.first?.ingredientName, "flour")
        XCTAssertEqual(fetchedRecipe.tags?.count, 1)
        XCTAssertEqual(fetchedRecipe.tags?.first?.name, "Breakfast")
    }

    func testRecipeWithURLSourcePersists() throws {
        let context = try makeInMemoryContext()
        let url = try XCTUnwrap(URL(string: "https://example.com/recipe"))
        let recipe = RecipeModel(title: "Web Recipe", steps: ["Step 1"], isTypedSource: false, sourceURL: url)

        context.insert(recipe)
        try context.save()

        let fetched = try XCTUnwrap(try context.fetch(FetchDescriptor<RecipeModel>()).first)
        XCTAssertFalse(fetched.isTypedSource)
        XCTAssertEqual(fetched.sourceURL, url)
    }

    /// A row that arrives through CloudKit without its URL (another device or app version)
    /// must map to a typed recipe instead of crashing the list or a storage switch.
    func testURLSourcedRowWithoutAURLMapsToTyped() {
        let model = RecipeModel(title: "Soup", steps: [], isTypedSource: false, sourceURL: nil)

        XCTAssertEqual(model.toDomain().source, .typed)
    }

    func testURLSourcedRowMapsToItsURL() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com/soup"))
        let model = RecipeModel(title: "Soup", steps: [], isTypedSource: false, sourceURL: url)

        XCTAssertEqual(model.toDomain().source, .url(url))
    }
}
