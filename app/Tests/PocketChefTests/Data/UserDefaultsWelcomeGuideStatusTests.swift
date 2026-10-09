@testable import PocketChef
import XCTest

@MainActor
final class UserDefaultsWelcomeGuideStatusTests: XCTestCase {
    /// A throwaway defaults domain, removed when the test ends.
    private func makeDefaults() -> UserDefaults {
        let suiteName = "UserDefaultsWelcomeGuideStatusTests-\(UUID().uuidString)"
        addTeardownBlock { UserDefaults().removePersistentDomain(forName: suiteName) }
        return UserDefaults(suiteName: suiteName)!
    }

    /// A first launch, and an install from before the guide existed: neither has the flag.
    func testIsUnseenWithoutTheFlag() {
        XCTAssertFalse(UserDefaultsWelcomeGuideStatus(defaults: makeDefaults()).hasSeen)
    }

    func testRemembersItWasSeenAcrossInstances() {
        let defaults = makeDefaults()

        UserDefaultsWelcomeGuideStatus(defaults: defaults).markSeen()

        XCTAssertTrue(UserDefaultsWelcomeGuideStatus(defaults: defaults).hasSeen)
        XCTAssertTrue(defaults.bool(forKey: "hasSeenWelcomeGuide"))
    }

    /// The unit tests' host app and UI test runs must not show the guide by themselves, nor
    /// touch the developer's own flag (PocketChefApp.makeWelcomeGuideStatus).
    func testTheTestHostIsRecognized() {
        XCTAssertTrue(PocketChefApp.isHostingUnitTests)
    }
}
