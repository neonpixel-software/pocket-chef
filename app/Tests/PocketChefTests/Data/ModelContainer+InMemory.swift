@testable import PocketChef
import SwiftData

extension ModelContainer {
    /// An in-memory container for tests. It names no CloudKit database on purpose: the default
    /// (.automatic) mirrors the store to CloudKit once the build has the iCloud entitlement (a
    /// local Signing.xcconfig), and then fails to load on DensityEntryModel's unique constraint
    /// (#130). The same reason RecipeStore names the database for every configuration.
    static func inMemory(schema: Schema = RecipeStore.schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
