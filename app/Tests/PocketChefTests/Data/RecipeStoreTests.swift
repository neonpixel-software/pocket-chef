@testable import PocketChef
import SwiftData
import XCTest

final class RecipeStoreTests: XCTestCase {
    func testLocalStoreKeepsSwiftDatasDefaultFileAndDoesNotSync() {
        let configuration = RecipeStore.configuration(for: .local)

        XCTAssertEqual(configuration.url.lastPathComponent, "default.store")
        XCTAssertNil(configuration.cloudKitContainerIdentifier)
    }

    func testICloudStoreUsesItsOwnFileAndThePrivateCloudKitContainer() {
        let configuration = RecipeStore.configuration(for: .iCloud)

        XCTAssertEqual(configuration.url.lastPathComponent, "iCloud.store")
        XCTAssertEqual(configuration.cloudKitContainerIdentifier, "iCloud.com.neonpixel.pocketchef")
    }

    func testDensityEntriesAreNotPartOfTheSyncedSchema() {
        let entityNames = RecipeStore.schema.entities.map(\.name)

        XCTAssertFalse(entityNames.contains("DensityEntryModel"))
        XCTAssertEqual(Set(entityNames), ["RecipeModel", "IngredientLineModel", "TagModel"])
    }

    /// Stores created before Phase 4.1 also hold DensityEntryModel. Opening one with the
    /// recipe-only schema must migrate it and keep the recipes, since the Local store stays
    /// at SwiftData's default location on existing devices.
    func testAStoreCreatedWithTheDensityModelOpensWithTheRecipeSchemaAndKeepsItsRecipes() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "default.store")

        do {
            let oldSchema = Schema([RecipeModel.self, IngredientLineModel.self, TagModel.self, DensityEntryModel.self])
            let oldContainer = try ModelContainer(
                for: oldSchema,
                configurations: ModelConfiguration(schema: oldSchema, url: url, cloudKitDatabase: .none)
            )
            let context = ModelContext(oldContainer)
            context.insert(RecipeModel(title: "Pancakes", steps: ["Fry"], isTypedSource: true))
            context.insert(DensityEntryModel(ingredientName: "flour", gramsPerMilliliter: 0.53))
            try context.save()
        }

        let container = try ModelContainer(
            for: RecipeStore.schema,
            configurations: ModelConfiguration(schema: RecipeStore.schema, url: url, cloudKitDatabase: .none)
        )

        let recipes = try SwiftDataRecipeRepository(modelContext: ModelContext(container)).fetchAll()
        XCTAssertEqual(recipes.map(\.title), ["Pancakes"])
    }
}
