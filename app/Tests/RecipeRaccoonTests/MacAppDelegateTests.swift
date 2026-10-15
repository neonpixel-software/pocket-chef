#if os(macOS)
@testable import RecipeRaccoon
import AppKit
import XCTest

@MainActor
final class MacAppDelegateTests: XCTestCase {
    func testRegistersForRemoteNotificationsAtLaunchWhenICloudIsEnabled() {
        var registrations = 0
        let sut = MacAppDelegate(isICloudEnabled: true, registerForRemoteNotifications: { registrations += 1 })

        sut.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        XCTAssertEqual(registrations, 1)
    }

    func testSkipsTheRegistrationWithoutICloud() {
        var registrations = 0
        let sut = MacAppDelegate(isICloudEnabled: false, registerForRemoteNotifications: { registrations += 1 })

        sut.applicationDidFinishLaunching(Notification(name: NSApplication.didFinishLaunchingNotification))

        XCTAssertEqual(registrations, 0)
    }
}
#endif
