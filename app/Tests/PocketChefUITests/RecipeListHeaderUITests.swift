import XCTest

/// The recipe list's header stays pinned to the top of the window: when the list shows an
/// empty or error state instead of recipes (#96, #98), and while the recipes scroll under it.
/// The empty and error states only take the height they need, and without the column filling
/// the window the whole column, header included, was centered in it. ViewInspector can't see
/// laid-out positions, hence a UI test.
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

        // The scenario starts with the Dinner tag selected (UITestScenario.selectedTagName).
        let tagChip = app.buttons["Dinner"]
        XCTAssertTrue(tagChip.waitForExistence(timeout: 10))
        XCTAssertTrue(tagChip.isSelected, "The Dinner chip isn't selected")

        XCTAssertTrue(text("No Recipes With This Tag", in: app).waitForExistence(timeout: 10))
        assertHeaderIsAtTop(in: app)
    }

    @MainActor
    func testHeaderStaysAtTopWhenRecipesFailToLoad() {
        let app = launch(scenario: "loadError")

        XCTAssertTrue(text("Couldn't Load Recipes", in: app).waitForExistence(timeout: 10))
        assertHeaderIsAtTop(in: app)
    }

    @MainActor
    func testHeaderStaysAtTopWhileTheRecipesScroll() {
        let app = launch(scenario: "manyRecipes")

        let firstRecipe = app.buttons["Recipe 01"]
        XCTAssertTrue(firstRecipe.waitForExistence(timeout: 10))
        let firstRecipeTop = firstRecipe.frame.minY
        let headerBefore = assertHeaderIsAtTop(in: app)

        let list = app.scrollViews["RecipeList"]
        XCTAssertTrue(list.exists, "The recipe list is missing")
        #if os(macOS)
        list.scroll(byDeltaX: 0, deltaY: -600)
        #else
        list.swipeUp()
        #endif

        // A lazy list drops rows that scrolled far out of view.
        let scrolled = !firstRecipe.exists || firstRecipe.frame.minY < firstRecipeTop - 100
        XCTAssertTrue(scrolled, "The recipe list didn't scroll, so this checked nothing")
        let headerAfter = assertHeaderIsAtTop(in: app)
        XCTAssertEqual(headerAfter.minY, headerBefore.minY, accuracy: 1, "The header moved while the list scrolled")
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
    private func text(_ string: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR value == %@", string, string)).firstMatch
    }

    /// The title sits at the bottom of the pink band right under the toolbar, so it starts a few
    /// points below the bar: 6.5 pt on macOS (at any window size) and 8 pt on an iPhone 17.
    /// With the column centered (#96) it started 163 pt or more below it in the UI test window (900 × 600 under the toolbar).
    /// Returns the title's frame.
    @MainActor
    @discardableResult
    private func assertHeaderIsAtTop(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) -> CGRect {
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
            "The header title is \(gap) pt from the bottom of the toolbar (negative is above it); it belongs right under it",
            file: file,
            line: line
        )
        return title.frame
    }
}
