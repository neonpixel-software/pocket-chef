@testable import PocketChef
import SwiftData
import XCTest

final class ModelContextDeduplicateTagsTests: XCTestCase {
    private func makeInMemoryContext() throws -> ModelContext {
        let container = try ModelContainer.inMemory()
        return ModelContext(container)
    }

    func testMergesTagsWithTheSameNameIgnoringCaseAndWhitespace() throws {
        let context = try makeInMemoryContext()
        context.insert(TagModel(name: "Brunch", isPreset: false))
        context.insert(TagModel(name: " brunch ", isPreset: false))
        context.insert(TagModel(name: "Dinner", isPreset: true))
        try context.save()

        let changed = try context.deduplicateTags()

        XCTAssertTrue(changed)
        let names = try context.fetch(FetchDescriptor<TagModel>()).map(\.name).sorted()
        XCTAssertEqual(names.count, 2)
        XCTAssertTrue(names.contains("Dinner"))
    }

    func testKeepsThePresetOverACustomTagWithTheSameName() throws {
        let context = try makeInMemoryContext()
        try context.insert(TagModel(id: XCTUnwrap(UUID(uuidString: "00000000-0000-0000-0000-000000000001")), name: "breakfast", isPreset: false))
        try context.insert(TagModel(id: XCTUnwrap(UUID(uuidString: "FFFFFFFF-0000-0000-0000-000000000000")), name: "Breakfast", isPreset: true))
        try context.save()

        try context.deduplicateTags()

        let remaining = try context.fetch(FetchDescriptor<TagModel>())
        XCTAssertEqual(remaining.map(\.name), ["Breakfast"])
        XCTAssertEqual(remaining.map(\.isPreset), [true])
    }

    /// Two devices deduplicating the same pair must keep the same row, or each deletes the
    /// other's copy and the tag disappears from both.
    func testKeepsTheSmallestIDAmongEqualCandidates() throws {
        let context = try makeInMemoryContext()
        let smaller = try XCTUnwrap(UUID(uuidString: "11111111-0000-0000-0000-000000000000"))
        let larger = try XCTUnwrap(UUID(uuidString: "99999999-0000-0000-0000-000000000000"))
        context.insert(TagModel(id: larger, name: "Lunch", isPreset: true))
        context.insert(TagModel(id: smaller, name: "Lunch", isPreset: true))
        try context.save()

        try context.deduplicateTags()

        XCTAssertEqual(try context.fetch(FetchDescriptor<TagModel>()).map(\.id), [smaller])
    }

    func testMovesRecipesFromTheRemovedTagToTheKeptOne() throws {
        let context = try makeInMemoryContext()
        let keptID = try XCTUnwrap(UUID(uuidString: "11111111-0000-0000-0000-000000000000"))
        let kept = TagModel(id: keptID, name: "Dessert", isPreset: true)
        let duplicate = try TagModel(id: XCTUnwrap(UUID(uuidString: "99999999-0000-0000-0000-000000000000")), name: "Dessert", isPreset: true)
        context.insert(RecipeModel(title: "Pie", steps: [], isTypedSource: true, tags: [duplicate]))
        context.insert(RecipeModel(title: "Cake", steps: [], isTypedSource: true, tags: [kept, duplicate]))
        try context.save()

        try context.deduplicateTags()

        let recipes = try SwiftDataRecipeRepository(modelContext: context).fetchAll()
        XCTAssertEqual(recipes.map(\.title), ["Cake", "Pie"])
        for recipe in recipes {
            XCTAssertEqual(recipe.tags.map(\.id), [keptID], recipe.title)
        }
    }

    func testReportsNoChangeWhenThereAreNoDuplicates() throws {
        let context = try makeInMemoryContext()
        context.insert(TagModel(name: "Breakfast", isPreset: true))
        context.insert(TagModel(name: "Brunch", isPreset: false))
        try context.save()

        XCTAssertFalse(try context.deduplicateTags())
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<TagModel>()), 2)
    }
}
