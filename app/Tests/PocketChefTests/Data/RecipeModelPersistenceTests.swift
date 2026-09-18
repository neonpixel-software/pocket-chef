import XCTest
import SwiftData
@testable import PocketChef

final class RecipeModelPersistenceTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        let schema = Schema([
            RecipeModel.self,
            IngredientLineModel.self,
            TagModel.self,
            DensityEntryModel.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
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
}
