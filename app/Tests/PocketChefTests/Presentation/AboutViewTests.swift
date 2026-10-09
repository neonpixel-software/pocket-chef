@testable import PocketChef
import SwiftUI
import ViewInspector
import XCTest

/// The About page (14.2): its links and footer.
@MainActor
final class AboutViewTests: XCTestCase {
    func testViewTheCodeOpensTheRepository() throws {
        let link = try AboutView().inspect().find(ViewType.Link.self) { try $0.labelView().text().string() == "View the Code on GitHub" }

        XCTAssertEqual(try link.url(), AboutInfo.repositoryURL)
    }

    func testReportAnIssueOpensANewIssue() throws {
        let link = try AboutView().inspect().find(ViewType.Link.self) { try $0.labelView().text().string() == "Report an Issue" }

        XCTAssertEqual(try link.url(), AboutInfo.newIssueURL)
    }

    func testTheFooterShowsTheVersion() throws {
        let sut = AboutView(info: AboutInfo(version: "1.2.3", build: "45"))

        XCTAssertNoThrow(try sut.inspect().find(text: "Version 1.2.3 (45)"))
        XCTAssertNoThrow(try sut.inspect().find(text: "Made by NeonPixel"))
    }
}
