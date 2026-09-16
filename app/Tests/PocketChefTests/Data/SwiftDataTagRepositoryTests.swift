import XCTest
import SwiftData
@testable import PocketChef

final class SwiftDataTagRepositoryTests: XCTestCase {
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

    func testFetchAllReturnsEmptyArrayWhenNoTagsStored() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataTagRepository(modelContext: context)

        XCTAssertEqual(try repository.fetchAll(), [])
    }

    func testFetchAllReturnsTagsSortedByName() throws {
        let context = try makeInMemoryContext()
        context.insert(TagModel(name: "Snack", isPreset: true))
        context.insert(TagModel(name: "Breakfast", isPreset: true))
        try context.save()

        let repository = SwiftDataTagRepository(modelContext: context)
        let tags = try repository.fetchAll()

        XCTAssertEqual(tags.map(\.name), ["Breakfast", "Snack"])
    }

    func testFindOrCreateReturnsExistingTagCaseInsensitively() throws {
        let context = try makeInMemoryContext()
        let existingID = UUID()
        context.insert(TagModel(id: existingID, name: "Breakfast", isPreset: true))
        try context.save()

        let repository = SwiftDataTagRepository(modelContext: context)
        let tag = try repository.findOrCreate(name: "breakfast")

        XCTAssertEqual(tag.id, existingID)
        XCTAssertEqual(tag.name, "Breakfast")

        let allTagRows = try context.fetch(FetchDescriptor<TagModel>())
        XCTAssertEqual(allTagRows.count, 1)
    }

    func testFindOrCreateCreatesNewTagWhenNoMatch() throws {
        let context = try makeInMemoryContext()
        let repository = SwiftDataTagRepository(modelContext: context)

        let tag = try repository.findOrCreate(name: "  Spicy  ")

        XCTAssertEqual(tag.name, "Spicy")
        XCTAssertFalse(tag.isPreset)

        let allTags = try repository.fetchAll()
        XCTAssertEqual(allTags, [tag])
    }
}
