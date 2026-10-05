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
        return app
    }

    /// iOS exposes a text's string as its label, macOS as its value.
    @MainActor
    private func text(_ string: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", string, string)).firstMatch
    }

    /// The title sits at the bottom of the pink band right under the toolbar, so it starts a few
    /// points below the bar: 6.5 pt on macOS and 8 pt on an iPhone 17. With the column centered
    /// (#96) it started 62 pt or more below it in a default-size Mac window.
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
