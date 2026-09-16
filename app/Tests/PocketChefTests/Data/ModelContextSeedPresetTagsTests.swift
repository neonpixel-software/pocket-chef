import XCTest
import SwiftData
@testable import PocketChef

final class ModelContextSeedPresetTagsTests: XCTestCase {
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

    func testSeedsFivePresetTagsWhenStoreIsEmpty() throws {
        let context = try makeInMemoryContext()

        context.seedPresetTagsIfNeeded()

        let repository = SwiftDataTagRepository(modelContext: context)
        let tags = try repository.fetchAll()
        XCTAssertEqual(tags.map(\.name), ["Breakfast", "Dessert", "Dinner", "Lunch", "Snack"])
        XCTAssertTrue(tags.allSatisfy(\.isPreset))
    }

    func testIsIdempotentAndDoesNotDuplicatePresetsOnSecondCall() throws {
        let context = try makeInMemoryContext()

        context.seedPresetTagsIfNeeded()
        context.seedPresetTagsIfNeeded()

        let allTagRows = try context.fetch(FetchDescriptor<TagModel>())
        XCTAssertEqual(allTagRows.count, 5)
    }

    func testSeedsOnlyMissingPresetsWhenSomeAlreadyExist() throws {
        // Simulates a store that already has "preset-like" tags from an older
        // seeding path (e.g. sample data) predating a preset list change.
        let context = try makeInMemoryContext()
        context.insert(TagModel(name: "Breakfast", isPreset: true))
        context.insert(TagModel(name: "Dinner", isPreset: true))
        try context.save()

        context.seedPresetTagsIfNeeded()

        let repository = SwiftDataTagRepository(modelContext: context)
        let tags = try repository.fetchAll()
        XCTAssertEqual(tags.map(\.name), ["Breakfast", "Dessert", "Dinner", "Lunch", "Snack"])
    }

    func testMatchesExistingNamesCaseInsensitively() throws {
        let context = try makeInMemoryContext()
        context.insert(TagModel(name: "breakfast", isPreset: false)) // pre-existing custom tag, different case
        try context.save()

        context.seedPresetTagsIfNeeded()

        let allTagRows = try context.fetch(FetchDescriptor<TagModel>())
        // "breakfast" isn't duplicated as a second "Breakfast" preset row.
        XCTAssertEqual(allTagRows.count, 5)
    }
}
