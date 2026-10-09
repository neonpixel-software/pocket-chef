import Foundation
import SwiftData

/// Builds the SwiftData container for each storage mode.
enum RecipeStore {
    static let cloudKitContainerIdentifier = "iCloud.com.neonpixel.pocketchef"

    /// The models that sync. DensityEntryModel is a local cache (PLAN.md "Storage & sync")
    /// and gets its own local-only container in Phase 10.
    static let schema = Schema([
        RecipeModel.self,
        IngredientLineModel.self,
        TagModel.self,
        RecipePhotoModel.self,
    ])

    /// Every configuration names its CloudKit database explicitly: once the app has the iCloud
    /// entitlement, SwiftData's default (.automatic) would sync the Local store too.
    static func configuration(for mode: StorageMode) -> ModelConfiguration {
        switch mode {
        case .local:
            // SwiftData's default store location, so recipes saved before Phase 4.1 are kept.
            ModelConfiguration(
                "Local",
                schema: schema,
                url: storeDirectory.appending(path: "default.store"),
                cloudKitDatabase: .none
            )
        case .iCloud:
            ModelConfiguration(
                "iCloud",
                schema: schema,
                url: storeDirectory.appending(path: "iCloud.store"),
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
        }
    }

    static func makeContainer(for mode: StorageMode) throws -> ModelContainer {
        // An explicit url, unlike the default configuration, doesn't create the directory.
        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        return try ModelContainer(for: schema, configurations: configuration(for: mode))
    }

    /// An empty store that's never written to disk or synced, for UI test runs and the unit
    /// tests' host app. Ignores the storage mode.
    static func makeInMemoryContainer(for _: StorageMode = .local) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true, cloudKitDatabase: .none))
    }

    private static var storeDirectory: URL {
        URL.applicationSupportDirectory
    }
}
