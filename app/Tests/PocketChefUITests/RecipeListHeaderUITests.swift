import XCTest

/// The recipe list's header stays pinned to the top of the window when the list shows an
/// empty or error state instead of recipes (#96, #98). Those states only take the height they
/// need, and without the column filling the window the whole column, header included, was
/// centered in it. ViewInspector can't see laid-out positions, hence a UI test.
final class RecipeListHeaderUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testHeaderStaysAtTopWhenThereAreNoRecipes() {
        let app = launch(scenario: "empty")

        XCTAssertTrue(text("No Recipes Yet", in: app).waitForExistence(timeout: 10))
        assertHeaderIsAtTop(in: app)
    }

    @MainActor
    func testHeaderStaysAtTopWhenNoRecipeHasTheSelectedTag() {
        let app = launch(scenario: "noMatchingTag")

        let tagChip = app.buttons["Dinner"]
        XCTAssertTrue(tagChip.waitForExistence(timeout: 10))
        tagChip.tap()
        XCTAssertTrue(tagChip.wait(for: \.isSelected, toEqual: true, timeout: 10), "Tapping the Dinner chip didn't select it")

        XCTAssertTrue(text("No Recipes With This Tag", in: app).waitForExistence(timeout: 10))
        assertHeaderIsAtTop(in: app)
    }

    @MainActor
    func testHeaderStaysAtTopWhenRecipesFailToLoad() {
        let app = launch(scenario: "loadError")

        XCTAssertTrue(text("Couldn't Load Recipes", in: app).waitForExistence(timeout: 10))
        assertHeaderIsAtTop(in: app)
    }

    // MARK: - Helpers

    @MainActor
    private func launch(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        // English, so the empty-state titles above match whatever the test machine's language.
        // Ignoring the saved window state, or macOS reopens no window when the last run ended
        // with it closed.
        app.launchArguments = [
            "-UITestScenario", scenario,
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
            "-ApplePersistenceIgnoreState", "YES",
        ]
        app.launch()
        #if os(macOS)
        // On CI another app can be in front, and then the first click only activates the window.
        app.activate()
        // The app pins its content to 900 × 600 under the toolbar in a UI test run
        // (UITestScenario.macContentSize), whatever size the last run left the window.
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 10), "The window is missing")
        let contentHeight = window.frame.height - app.toolbars.firstMatch.frame.height
        XCTAssertEqual(contentHeight, 600, accuracy: 1, "The window isn't the UI test size")
        #endif
        return app
    }

    /// iOS exposes a text's string as its label, macOS as its value.
    @MainActor
    private func text(_ string: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", string, string)).firstMatch
    }

    /// The title sits at the bottom of the pink band right under the toolbar, so it starts a few
    /// points below the bar: 6.5 pt on macOS (at any window size) and 8 pt on an iPhone 17.
    /// With the column centered (#96) it started 163 pt or more below it in the UI test window (900 × 600 under the toolbar).
    @MainActor
    private func assertHeaderIsAtTop(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let titles = app.descendants(matching: .any).matching(identifier: "PCHeader.title")
        let title = titles.firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 10), "The header title is missing", file: file, line: line)
        XCTAssertEqual(titles.count, 1, "The header title should be one accessibility element", file: file, line: line)

        #if os(macOS)
        let bar = app.toolbars.firstMatch
        #else
        let bar = app.navigationBars.firstMatch
        #endif
        XCTAssertTrue(bar.exists, "The toolbar is missing", file: file, line: line)

        let gap = title.frame.minY - bar.frame.maxY
        XCTAssertTrue(
            (0..<20).contains(gap),
            "The header title starts \(gap) pt below the toolbar; it belongs right under it",
            file: file,
            line: line
        )
    }
}
