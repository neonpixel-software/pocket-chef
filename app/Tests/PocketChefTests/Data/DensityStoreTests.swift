@testable import PocketChef
import SwiftData
import XCTest

final class DensityStoreTests: XCTestCase {
    func testTheSchemaHoldsOnlyDensityEntries() {
        XCTAssertEqual(DensityStore.schema.entities.map(\.name), ["DensityEntryModel"])
    }

    /// The cache must never sync: it isn't user data, and CloudKit forbids its unique key.
    func testTheStoreIsLocalOnlyAndSeparateFromTheRecipeStores() {
        let configuration = DensityStore.configuration()

        XCTAssertNil(configuration.cloudKitContainerIdentifier)
        XCTAssertEqual(configuration.url.lastPathComponent, "density.store")
        XCTAssertNotEqual(configuration.url, RecipeStore.configuration(for: .local).url)
        XCTAssertNotEqual(configuration.url, RecipeStore.configuration(for: .iCloud).url)
    }
}
