import XCTest
import SwiftData
@testable import PocketChef

final class SwiftDataRecipeRepositoryTests: XCTestCase {
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

    func testFetchAllReturnsEmptyArrayWhenNoRecipesStored() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)

        let recipes = try repository.fetchAll()

        XCTAssertEqual(recipes, [])
    }

    func testFetchAllReturnsRecipesSortedByTitleWithIngredientsAndTags() throws {
        let context = try makeInMemoryContext()
        context.insert(RecipeModel(
            title: "Waffles",
            steps: ["Cook in waffle iron"],
            isTypedSource: true,
            ingredients: [IngredientLineModel(rawText: "2 cups flour", amount: 2, unit: "cup", ingredientName: "flour")],
            tags: [TagModel(name: "Breakfast", isPreset: true)]
        ))
        context.insert(RecipeModel(title: "Apple Pie", steps: ["Bake"], isTypedSource: true))
        try context.save()

        let repository = SwiftDataRecipeRepository(modelContext: context)
        let recipes = try repository.fetchAll()

        XCTAssertEqual(recipes.map(\.title), ["Apple Pie", "Waffles"])
        let waffles = try XCTUnwrap(recipes.first { $0.title == "Waffles" })
        XCTAssertEqual(waffles.ingredients.first?.ingredientName, "flour")
        XCTAssertEqual(waffles.tags.first?.name, "Breakfast")
    }

    func testFetchAllMapsURLSourceRecipe() throws {
        let context = try makeInMemoryContext()
        let url = try XCTUnwrap(URL(string: "https://example.com/recipe"))
        context.insert(RecipeModel(title: "Web Recipe", steps: ["Step 1"], isTypedSource: false, sourceURL: url))
        try context.save()

        let repository = SwiftDataRecipeRepository(modelContext: context)
        let recipes = try repository.fetchAll()

        XCTAssertEqual(recipes.first?.source, .url(url))
    }
}
