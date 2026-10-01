@testable import PocketChef
import XCTest

final class UserDefaultsDensityRefreshLogTests: XCTestCase {
    private var suiteName = ""
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "UserDefaultsDensityRefreshLogTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        super.tearDown()
    }

    func testHasNoRefreshUntilOneIsRecorded() {
        XCTAssertNil(UserDefaultsDensityRefreshLog(defaults: defaults).lastRefresh)
    }

    func testRemembersTheRecordedRefreshAcrossInstances() {
        let date = Date(timeIntervalSince1970: 1_790_000_000)

        UserDefaultsDensityRefreshLog(defaults: defaults).recordRefresh(at: date)

        XCTAssertEqual(UserDefaultsDensityRefreshLog(defaults: defaults).lastRefresh, date)
    }
}
