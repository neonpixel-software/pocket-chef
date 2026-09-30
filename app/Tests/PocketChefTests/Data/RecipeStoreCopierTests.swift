@testable import PocketChef
import SwiftData
import XCTest

final class RecipeStoreCopierTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        let configuration = ModelConfiguration(schema: RecipeStore.schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: RecipeStore.schema, configurations: [configuration])
        return ModelContext(container)
    }

    private func recipes(in context: ModelContext) throws -> [Recipe] {
        try SwiftDataRecipeRepository(modelContext: context).fetchAll()
    }

    private func tagNames(in context: ModelContext) throws -> [String] {
        try SwiftDataTagRepository(modelContext: context).fetchAll().map(\.name)
    }

    func testMergeCopiesRecipesWithIngredientsInOrderAndKeepsIDs() throws {
        let source = try makeInMemoryContext()
        let target = try makeInMemoryContext()
        let recipe = try Recipe(
            id: UUID(),
            title: "Pancakes",
            ingredients: [
                IngredientLine(id: UUID(), rawText: "2 cups flour", amount: 2, unit: "cup", ingredientName: "flour"),
                IngredientLine(id: UUID(), rawText: "1 egg", amount: 1, unit: nil, ingredientName: "egg"),
            ],
            equipment: ["skillet"],
            steps: ["Mix", "Fry"],
            source: .url(XCTUnwrap(URL(string: "https://example.com/pancakes"))),
            tags: []
        )
        try SwiftDataRecipeRepository(modelContext: source).create(recipe)

        try RecipeStoreCopier.merge(from: source, into: target)

        XCTAssertEqual(try recipes(in: target), [recipe])
    }

    func testMergeMatchesTagsByNameIgnoringCaseAndCopiesUnusedCustomTags() throws {
        let source = try makeInMemoryContext()
        let target = try makeInMemoryContext()
        target.insert(TagModel(name: "Breakfast", isPreset: true))
        try target.save()
        let sourceBreakfast = TagModel(name: "breakfast", isPreset: true)
        source.insert(sourceBreakfast)
        source.insert(TagModel(name: "Brunch", isPreset: false))
        source.insert(RecipeModel(title: "Waffles", steps: [], isTypedSource: true, tags: [sourceBreakfast]))
        try source.save()

        try RecipeStoreCopier.merge(from: source, into: target)

        XCTAssertEqual(try tagNames(in: target), ["Breakfast", "Brunch"])
        XCTAssertEqual(try recipes(in: target).first?.tags.map(\.name), ["Breakfast"])
    }

    func testMergeOverwritesARecipeWithTheSameIDInsteadOfDuplicatingIt() throws {
        let source = try makeInMemoryContext()
        let target = try makeInMemoryContext()
        let id = UUID()
        target.insert(RecipeModel(
            id: id,
            title: "Old title",
            steps: ["Old step"],
            isTypedSource: true,
            ingredients: [IngredientLineModel(rawText: "old line")]
        ))
        try target.save()
        source.insert(RecipeModel(
            id: id,
            title: "New title",
            steps: ["New step"],
            isTypedSource: true,
            ingredients: [IngredientLineModel(rawText: "new line")]
        ))
        try source.save()

        try RecipeStoreCopier.merge(from: source, into: target)

        let merged = try recipes(in: target)
        XCTAssertEqual(merged.map(\.title), ["New title"])
        XCTAssertEqual(merged.first?.ingredients.map(\.rawText), ["new line"])
        XCTAssertEqual(try target.fetchCount(FetchDescriptor<IngredientLineModel>()), 1)
    }

    func testMergeKeepsRecipesThatOnlyExistInTheTarget() throws {
        let source = try makeInMemoryContext()
        let target = try makeInMemoryContext()
        target.insert(RecipeModel(title: "From another device", steps: [], isTypedSource: true))
        try target.save()
        source.insert(RecipeModel(title: "Local recipe", steps: [], isTypedSource: true))
        try source.save()

        try RecipeStoreCopier.merge(from: source, into: target)

        XCTAssertEqual(try recipes(in: target).map(\.title), ["From another device", "Local recipe"])
    }

    func testReplaceEmptiesTheTargetBeforeCopying() throws {
        let source = try makeInMemoryContext()
        let target = try makeInMemoryContext()
        target.insert(RecipeModel(
            title: "Deleted while syncing",
            steps: [],
            isTypedSource: true,
            ingredients: [IngredientLineModel(rawText: "stale line")],
            tags: [TagModel(name: "Stale tag", isPreset: false)]
        ))
        try target.save()
        source.insert(RecipeModel(title: "Synced recipe", steps: [], isTypedSource: true))
        source.insert(TagModel(name: "Dinner", isPreset: true))
        try source.save()

        try RecipeStoreCopier.replace(contentsOf: target, with: source)

        XCTAssertEqual(try recipes(in: target).map(\.title), ["Synced recipe"])
        XCTAssertEqual(try tagNames(in: target), ["Dinner"])
        XCTAssertEqual(try target.fetchCount(FetchDescriptor<IngredientLineModel>()), 0)
    }

    func testMergeLeavesTheSourceUntouched() throws {
        let source = try makeInMemoryContext()
        let target = try makeInMemoryContext()
        source.insert(RecipeModel(title: "Pancakes", steps: [], isTypedSource: true))
        try source.save()

        try RecipeStoreCopier.merge(from: source, into: target)

        XCTAssertEqual(try recipes(in: source).map(\.title), ["Pancakes"])
    }
}
