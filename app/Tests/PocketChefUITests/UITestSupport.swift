import XCTest

/// Shared by the UI tests: launching a UITestScenario and checking the PCHeader.
extension XCTestCase {
    /// The app set up for a UITestScenario (Data/DevSupport/UITestScenario.swift), not launched
    /// yet. Most tests use `launch(scenario:)`.
    @MainActor
    func makeApp(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        // English, so the texts the tests look for match whatever the test machine's language.
        // Ignoring the saved window state, or macOS reopens no window when the last run ended
        // with it closed.
        app.launchArguments = [
            "-UITestScenario", scenario,
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-ApplePersistenceIgnoreState", "YES",
        ]
        return app
    }

    /// Launches the app in a UITestScenario and checks the recipe window came up at the test size.
    @MainActor
    func launch(scenario: String) -> XCUIApplication {
        let app = makeApp(scenario: scenario)
        app.launch()
        #if os(macOS)
        // The app pins its content to 900 × 600 under the toolbar in a UI test run
        // (UITestScenario.macContentSize), whatever size the last run left the window.
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10), "The window is missing")
        let contentHeight = window.frame.height - app.toolbars.firstMatch.frame.height
        XCTAssertEqual(contentHeight, 600, accuracy: 1, "The window isn't the UI test size")
        #else
        // The fixed test size is for the Mac window only; on iOS the content fills the screen.
        let bar = app.navigationBars.firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 10), "The navigation bar is missing")
        XCTAssertEqual(bar.frame.width, app.windows.firstMatch.frame.width, accuracy: 1, "The content doesn't fit the screen")
        #endif
        return app
    }

    /// iOS exposes a text's string as its label, macOS as its value.
    @MainActor
    func text(_ string: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", string, string)).firstMatch
    }

    /// The bar the PCHeader sits under: the toolbar on macOS, the navigation bar on iOS.
    @MainActor
    func bar(in app: XCUIApplication) -> (element: XCUIElement, name: String) {
        #if os(macOS)
        (app.toolbars.firstMatch, "toolbar")
        #else
        (app.navigationBars.firstMatch, "navigation bar")
        #endif
    }

    /// The title sits at the bottom of the pink band right under the bar, so it starts a few
    /// points below it: 6.5 pt on macOS at any window size, 8 pt on an iPhone 17. Under 30 pt
    /// passes. The regressions are far off: with the list's column centered (#96) the title
    /// started 163 pt or more below the Mac toolbar, and with the header scrolling away it ended
    /// up hundreds of points above it.
    /// Returns the title's frame.
    @MainActor
    @discardableResult
    func assertHeaderIsAtTop(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> CGRect {
        let titles = app.descendants(matching: .any).matching(identifier: "PCHeader.title")
        let title = titles.firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10), "The header title is missing", file: file, line: line)
        XCTAssertEqual(titles.count, 1, "The header title should be one accessibility element", file: file, line: line)

        let (bar, barName) = bar(in: app)
        XCTAssertTrue(bar.exists, "The \(barName) is missing", file: file, line: line)

        let gap = title.frame.minY - bar.frame.maxY
        XCTAssertTrue(
            (0..<30).contains(gap),
            "The header title is \(gap) pt from the bottom of the \(barName) (negative is above it); it belongs right under it",
            file: file,
            line: line
        )
        return title.frame
    }
}
