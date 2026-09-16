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

    func testCreateInsertsRecipeRetrievableByFetchAll() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)
        let recipe = Recipe(
            id: UUID(),
            title: "Waffles",
            ingredients: [IngredientLine(id: UUID(), rawText: "2 cups flour", amount: 2, unit: "cup", ingredientName: "flour")],
            steps: ["Cook in waffle iron"],
            source: .typed,
            tags: []
        )

        try repository.create(recipe)

        let recipes = try repository.fetchAll()
        XCTAssertEqual(recipes, [recipe])
    }

    func testUpdateReplacesFieldsAndIngredientsWithoutOrphaningOldRows() throws {
        let context = try makeInMemoryContext()
        let recipeID = UUID()
        context.insert(RecipeModel(
            id: recipeID,
            title: "Original Title",
            steps: ["Old step"],
            isTypedSource: true,
            ingredients: [IngredientLineModel(rawText: "1 old ingredient")]
        ))
        try context.save()

        let repository = SwiftDataRecipeRepository(modelContext: context)
        let updated = Recipe(
            id: recipeID,
            title: "New Title",
            ingredients: [IngredientLine(id: UUID(), rawText: "2 cups sugar", amount: 2, unit: "cup", ingredientName: "sugar")],
            steps: ["New step"],
            source: .typed,
            tags: []
        )

        try repository.update(updated)

        let recipes = try repository.fetchAll()
        XCTAssertEqual(recipes, [updated])

        let remainingIngredients = try context.fetch(FetchDescriptor<IngredientLineModel>())
        XCTAssertEqual(remainingIngredients.map(\.rawText), ["2 cups sugar"])
    }

    func testCreateResolvesTagsToExistingTagModelRowsWithoutDuplicating() throws {
        let context = try makeInMemoryContext()
        let tagID = UUID()
        context.insert(TagModel(id: tagID, name: "Breakfast", isPreset: true))
        try context.save()

        let repository = SwiftDataRecipeRepository(modelContext: context)
        let tag = Tag(id: tagID, name: "Breakfast", isPreset: true)
        let recipe = Recipe(id: UUID(), title: "Waffles", ingredients: [], steps: [], source: .typed, tags: [tag])

        try repository.create(recipe)

        let recipes = try repository.fetchAll()
        XCTAssertEqual(recipes.first?.tags, [tag])

        let allTagRows = try context.fetch(FetchDescriptor<TagModel>())
        XCTAssertEqual(allTagRows.count, 1)
    }

    func testUpdateResolvesTagsToExistingTagModelRowsWithoutDuplicating() throws {
        let context = try makeInMemoryContext()
        let recipeID = UUID()
        let tagID = UUID()
        context.insert(RecipeModel(id: recipeID, title: "Waffles", steps: [], isTypedSource: true))
        context.insert(TagModel(id: tagID, name: "Breakfast", isPreset: true))
        try context.save()

        let repository = SwiftDataRecipeRepository(modelContext: context)
        let tag = Tag(id: tagID, name: "Breakfast", isPreset: true)
        let updated = Recipe(id: recipeID, title: "Waffles", ingredients: [], steps: [], source: .typed, tags: [tag])

        try repository.update(updated)

        let recipes = try repository.fetchAll()
        XCTAssertEqual(recipes.first?.tags, [tag])

        let allTagRows = try context.fetch(FetchDescriptor<TagModel>())
        XCTAssertEqual(allTagRows.count, 1)
    }

    func testUpdateThrowsRecipeNotFoundForUnknownID() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)
        let recipe = Recipe(id: UUID(), title: "Ghost", ingredients: [], steps: [], source: .typed, tags: [])

        XCTAssertThrowsError(try repository.update(recipe)) { error in
            XCTAssertEqual(error as? RecipeRepositoryError, .recipeNotFound)
        }
    }

    func testDeleteRemovesRecipe() throws {
        let context = try makeInMemoryContext()
        let recipeID = UUID()
        context.insert(RecipeModel(id: recipeID, title: "Waffles", steps: ["Cook"], isTypedSource: true))
        try context.save()

        let repository = SwiftDataRecipeRepository(modelContext: context)
        try repository.delete(id: recipeID)

        let recipes = try repository.fetchAll()
        XCTAssertEqual(recipes, [])
    }

    func testDeleteThrowsRecipeNotFoundForUnknownID() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataRecipeRepository(modelContext: context)

        XCTAssertThrowsError(try repository.delete(id: UUID())) { error in
            XCTAssertEqual(error as? RecipeRepositoryError, .recipeNotFound)
        }
    }
}
