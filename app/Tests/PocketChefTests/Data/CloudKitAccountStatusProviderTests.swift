import CloudKit
@testable import PocketChef
import XCTest

final class CloudKitAccountStatusProviderTests: XCTestCase {
    func testReportsNotConfiguredWithoutTouchingCloudKitInABuildWithoutICloud() async {
        let provider = CloudKitAccountStatusProvider(isEnabledInBuild: false)

        let status = await provider.status()

        XCTAssertEqual(status, .notConfiguredInBuild)
    }

    func testMapsEveryCloudKitAccountStatus() {
        XCTAssertEqual(CloudKitAccountStatusProvider.map(.available), .available)
        XCTAssertEqual(CloudKitAccountStatusProvider.map(.noAccount), .noAccount)
        XCTAssertEqual(CloudKitAccountStatusProvider.map(.restricted), .restricted)
        XCTAssertEqual(CloudKitAccountStatusProvider.map(.temporarilyUnavailable), .temporarilyUnavailable)
        XCTAssertEqual(CloudKitAccountStatusProvider.map(.couldNotDetermine), .couldNotDetermine)
    }
}
