import XCTest
import SwiftData
@testable import PocketChef

/// Regression test for the CloudKit schema-compatibility rework (issue #48):
/// unique attributes, non-optional attributes without defaults, and relationships
/// without an inverse all cause a CloudKit-backed ModelContainer to fail to load.
final class CloudKitSchemaCompatibilityTests: XCTestCase {
    func testCloudKitBackedContainerLoadsWithoutError() throws {
        let schema = Schema([
            RecipeModel.self,
            IngredientLineModel.self,
            TagModel.self,
            DensityEntryModel.self
        ])
        let configuration = ModelConfiguration(cloudKitDatabase: .private("iCloud.com.neonpixel.pocketchef"))

        XCTAssertNoThrow(try ModelContainer(for: schema, configurations: configuration))
    }
}
