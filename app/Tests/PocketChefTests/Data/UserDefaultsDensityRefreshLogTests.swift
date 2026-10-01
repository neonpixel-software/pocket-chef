@testable import PocketChef
import XCTest

@MainActor
final class UserDefaultsDensityRefreshLogTests: XCTestCase {
    /// A throwaway defaults domain, removed when the test ends.
    private func makeDefaults() -> UserDefaults {
        let suiteName = "UserDefaultsDensityRefreshLogTests-\(UUID().uuidString)"
        addTeardownBlock { UserDefaults().removePersistentDomain(forName: suiteName) }
        return UserDefaults(suiteName: suiteName)!
    }

    func testHasNoRefreshUntilOneIsRecorded() {
        XCTAssertNil(UserDefaultsDensityRefreshLog(defaults: makeDefaults()).lastRefresh)
    }

    func testRemembersTheRecordedRefreshAcrossInstances() {
        let defaults = makeDefaults()
        let date = Date(timeIntervalSince1970: 1_790_000_000)

        UserDefaultsDensityRefreshLog(defaults: defaults).recordRefresh(at: date)

        XCTAssertEqual(UserDefaultsDensityRefreshLog(defaults: defaults).lastRefresh, date)
    }
}
