@testable import PocketChef
import SwiftData
import XCTest

/// Regression test for the CloudKit schema-compatibility rework (issue #48):
/// unique attributes, non-optional attributes without defaults, and relationships
/// without an inverse all cause a CloudKit-backed ModelContainer to fail to load.
///
/// This only guards schema compatibility (does the container load), not actual
/// CloudKit sync — sync needs entitlements, a real container, and network, none
/// of which are wired up until Phase 4.
final class CloudKitSchemaCompatibilityTests: XCTestCase {
    func testCloudKitBackedContainerLoadsWithoutError() throws {
        let schema = Schema([
            RecipeModel.self,
            IngredientLineModel.self,
            TagModel.self,
            DensityEntryModel.self,
        ])
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .private("iCloud.com.neonpixel.pocketchef")
        )

        XCTAssertNoThrow(try ModelContainer(for: schema, configurations: configuration))
    }
}
