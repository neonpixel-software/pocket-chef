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

        // A lazy list drops rows that scrolled far out of view. Recipe 15 starts well below the
        // window on both platforms, so seeing it means the list really moved.
        let scrolled = !firstRecipe.exists || firstRecipe.frame.minY < firstRecipeTop - 100
        XCTAssertTrue(scrolled, "The recipe list didn't scroll, so this checked nothing")
        XCTAssertTrue(app.buttons["Recipe 15"].isHittable, "Recipe 15 didn't scroll into view")
        let headerAfter = assertHeaderIsAtTop(in: app)
        XCTAssertEqual(headerAfter.minY, headerBefore.minY, accuracy: 1, "The header moved while the list scrolled")
    }
}
