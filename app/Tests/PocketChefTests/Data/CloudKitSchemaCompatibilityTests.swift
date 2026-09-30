@testable import PocketChef
import SwiftData
import XCTest

/// Regression test for the CloudKit schema-compatibility rework (issue #48):
/// unique attributes, non-optional attributes without defaults, and relationships
/// without an inverse all cause a CloudKit-backed ModelContainer to fail to load.
///
/// This only guards schema compatibility (does the container load), not actual
/// CloudKit sync, which needs the entitlements from Signing.xcconfig, a real
/// container and network (verified on devices in Phase 4.1).
final class CloudKitSchemaCompatibilityTests: XCTestCase {
    func testCloudKitBackedContainerLoadsWithoutError() throws {
        let configuration = ModelConfiguration(
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .private(RecipeStore.cloudKitContainerIdentifier)
        )

        XCTAssertNoThrow(try ModelContainer(for: RecipeStore.schema, configurations: configuration))
    }
}
