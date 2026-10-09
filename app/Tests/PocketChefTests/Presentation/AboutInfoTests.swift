@testable import PocketChef
import XCTest

/// The About page's links and version (14.2).
final class AboutInfoTests: XCTestCase {
    func testTheLinksPointAtTheRepositoryAndANewIssue() {
        XCTAssertEqual(AboutInfo.repositoryURL.absoluteString, "https://github.com/neonpixel-software/pocket-chef")
        XCTAssertEqual(AboutInfo.newIssueURL.absoluteString, "https://github.com/neonpixel-software/pocket-chef/issues/new")
    }

    func testTheVersionTextShowsVersionAndBuild() {
        XCTAssertEqual(AboutInfo(version: "0.1.0", build: "1").versionText, "Version 0.1.0 (1)")
    }

    /// The running app's version comes from its Info.plist, so it matches the build.
    func testTheAppsVersionComesFromItsBundle() {
        let info = AboutInfo()

        XCTAssertEqual(info.version, Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
        XCTAssertEqual(info.build, Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
        XCTAssertNotEqual(info.version, "?")
    }
}
