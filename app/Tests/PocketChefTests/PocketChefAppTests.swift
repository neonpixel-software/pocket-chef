@testable import PocketChef
import SwiftData
import XCTest

@MainActor
final class PocketChefAppTests: XCTestCase {
    /// The unit tests' host app must never sync or open the developer's store: CloudKit
    /// imports there post recipeStoreDidChange, which the views under test react to (#160).
    /// With iCloud off its PersistenceController stays Local and ignores every remote change,
    /// including any a test posts on the default notification center.
    func testTheTestHostGetsAnInMemoryStoreWithoutICloud() throws {
        XCTAssertTrue(PocketChefApp.isHostingUnitTests)
        XCTAssertFalse(PocketChefApp.isICloudEnabled)

        let container = try PocketChefApp.makeContainer(.iCloud)

        XCTAssertFalse(container.configurations.isEmpty)
        for configuration in container.configurations {
            XCTAssertTrue(configuration.isStoredInMemoryOnly)
            XCTAssertNil(configuration.cloudKitContainerIdentifier)
        }
    }
}
