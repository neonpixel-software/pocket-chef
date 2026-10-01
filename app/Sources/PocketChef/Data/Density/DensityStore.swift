import Foundation
import SwiftData

/// Builds the container for the density cache: a local-only store next to the recipe stores.
/// It never syncs, since the entries can always be downloaded again (PLAN.md "Storage & sync").
enum DensityStore {
    static let schema = Schema([DensityEntryModel.self])

    static func configuration(inMemory: Bool = false) -> ModelConfiguration {
        if inMemory {
            return ModelConfiguration("Density", schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        }
        return ModelConfiguration(
            "Density",
            schema: schema,
            url: URL.applicationSupportDirectory.appending(path: "density.store"),
            cloudKitDatabase: .none
        )
    }

    static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        // An explicit url, unlike the default configuration, doesn't create the directory.
        try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
        return try ModelContainer(for: schema, configurations: configuration(inMemory: inMemory))
    }
}
