import XCTest

/// The welcome guide (14.1). Only the welcomeGuide scenario opens it; every other scenario
/// starts as if it had been seen. Taps and swipes don't reach the app on GitHub's macOS runner,
/// so the Mac gets a layout check of the guide's window instead.
final class WelcomeGuideUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testANormalScenarioLaunchDoesntShowTheGuide() {
        let app = launch(scenario: "empty")

        XCTAssertTrue(text("No Recipes Yet", in: app).waitForExistence(timeout: 10))
        XCTAssertEqual(guidePages(in: app).count, 0, "The guide opened in a scenario that didn't ask for it")
        #if os(macOS)
        XCTAssertFalse(app.windows[Self.windowTitle].exists)
        #endif
    }

    #if os(iOS)
    @MainActor
    func testNextWalksThroughThePagesAndGetStartedCloses() {
        let app = makeApp(scenario: "welcomeGuide")
        app.launch()

        XCTAssertTrue(page("Welcome to Pocket Chef", in: app).waitForExistence(timeout: 10))
        let label = page("Welcome to Pocket Chef", in: app).label
        XCTAssertTrue(label.hasSuffix("Page 1 of 4"), "The page doesn't say where it is: \(label)")
        for title in ["Add a Recipe", "Cook From It", "Make It Yours"] {
            app.buttons["Next"].tap()
            XCTAssertTrue(page(title, in: app).wait(for: \.isHittable, toEqual: true, timeout: 5), "Next didn't turn to \(title)")
        }
        XCTAssertFalse(app.buttons["Skip"].exists, "The last page still offers Skip")

        app.buttons["Get Started"].tap()

        XCTAssertTrue(text("No Recipes Yet", in: app).waitForExistence(timeout: 10), "Get Started didn't close the guide")
        XCTAssertEqual(guidePages(in: app).count, 0)
    }

    @MainActor
    func testSwipingTurnsThePageAndSkipCloses() {
        let app = makeApp(scenario: "welcomeGuide")
        app.launch()
        let first = page("Welcome to Pocket Chef", in: app)
        XCTAssertTrue(first.waitForExistence(timeout: 10))

        first.swipeLeft()
        XCTAssertTrue(page("Add a Recipe", in: app).wait(for: \.isHittable, toEqual: true, timeout: 5), "Swiping didn't turn the page")

        app.buttons["Skip"].tap()
        XCTAssertTrue(text("No Recipes Yet", in: app).waitForExistence(timeout: 10), "Skip didn't close the guide")
    }

    /// The guide replaces the Settings sheet: Settings closes first, then the guide opens.
    @MainActor
    func testSettingsReopensTheGuide() {
        let app = launch(scenario: "empty")
        app.buttons["Settings"].tap()
        let show = app.buttons["Show Welcome Guide"]
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 10))
        for _ in 0..<4 where !show.isHittable {
            app.swipeUp()
        }

        show.tap()

        XCTAssertTrue(page("Welcome to Pocket Chef", in: app).waitForExistence(timeout: 10), "The guide didn't open from Settings")
        XCTAssertFalse(app.navigationBars["Settings"].exists, "Settings is still open")
    }
    #else
    @MainActor
    func testTheGuideOpensInItsOwnWindowWithItsButtons() {
        let app = makeApp(scenario: "welcomeGuide")
        app.launch()

        let window = app.windows[Self.windowTitle]
        XCTAssertTrue(window.waitForExistence(timeout: 10), "The guide's window didn't open")
        let first = page("Welcome to Pocket Chef", in: app)
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(first.label.hasSuffix("Page 1 of 4"), "The page doesn't say where it is: \(first.label)")
        // 560 pt wide; its content 520 pt tall under the title bar.
        XCTAssertEqual(window.frame.width, 560, accuracy: 1)
        for button in [window.buttons["Skip"], window.buttons["Next"], window.buttons["Next Page"]] {
            XCTAssertTrue(button.exists, "\(button) is missing")
            XCTAssertTrue(window.frame.contains(button.frame), "\(button) isn't inside the window")
        }
        XCTAssertTrue(window.frame.contains(first.frame), "The page isn't inside the window")
    }
    #endif

    // MARK: - Helpers

    private static let windowTitle = "Welcome Guide"

    /// The guide's pages. Each page is one accessibility element, its label starting with the
    /// title and ending with its position.
    @MainActor
    private func guidePages(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(identifier: "WelcomeGuidePage")
    }

    @MainActor
    private func page(_ title: String, in app: XCUIApplication) -> XCUIElement {
        guidePages(in: app).matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch
    }
}
