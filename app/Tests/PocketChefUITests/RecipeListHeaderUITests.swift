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

        XCTAssertTrue(app.buttons["Recipe 01"].waitForExistence(timeout: 10))
        // Recipe 12 starts well below the window on both platforms; once it's on screen, the list
        // has really moved. Waiting for it also rides out the moment after a scroll when the macOS
        // runner's accessibility snapshot comes back without the rows: an earlier check read
        // Recipe 01's frame right then and failed with no buttons but the window's zoom button.
        let laterRecipe = app.buttons["Recipe 12"]
        // Nothing moves yet, so reading the frame can't race; isHittable on an off-screen element
        // made XCTest retry for 14 s on macOS.
        let windowBottom = app.windows.firstMatch.frame.maxY
        XCTAssertTrue(!laterRecipe.exists || laterRecipe.frame.minY >= windowBottom, "Recipe 12 is on screen before scrolling")
        let headerBefore = assertHeaderIsAtTop(in: app)

        let list = app.scrollViews["RecipeList"]
        XCTAssertTrue(list.exists, "The recipe list is missing")
        // A synthesized scroll on GitHub's macOS runner sometimes moves the list less, or not at
        // all, so scroll in steps until Recipe 12 is on screen. However far it goes, the header
        // has to stay put.
        var scrolled = false
        for _ in 0..<4 where !scrolled {
            #if os(macOS)
            list.scroll(byDeltaX: 0, deltaY: -600)
            #else
            list.swipeUp()
            #endif
            scrolled = waitUntilFullyInside(laterRecipe, window: app.windows.firstMatch.frame, timeout: 3)
        }
        let where12 = laterRecipe.exists ? "at \(laterRecipe.frame), window bottom \(windowBottom)" : "not loaded"
        XCTAssertTrue(scrolled, "The recipe list didn't scroll: after 4 scrolls Recipe 12 is \(where12), so this checked nothing")
        let headerAfter = assertHeaderIsAtTop(in: app)
        XCTAssertEqual(headerAfter.minY, headerBefore.minY, accuracy: 1, "The header moved while the list scrolled")
    }

    /// Waits until the element's frame lies within the window. Not isHittable: on the GitHub
    /// iOS runner, asking that of a row still settling after a swipe failed the test outright
    /// ("Activation point invalid") instead of returning false.
    @MainActor
    private func waitUntilFullyInside(_ element: XCUIElement, window: CGRect, timeout: TimeInterval) -> Bool {
        let inside = NSPredicate { _, _ in
            element.exists && window.contains(element.frame)
        }
        let expectation = XCTNSPredicateExpectation(predicate: inside, object: nil)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
