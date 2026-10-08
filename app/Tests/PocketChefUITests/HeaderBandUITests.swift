import XCTest

/// The PCHeader's geometry on both screens that use it (#104): the pink runs up behind the bar
/// to the top of the window, and the content starts right under the pink band. #101 fixed a
/// bar-high gap under the band (#94); the bleed and the band only show in laid-out pixels and
/// frames, hence a UI test.
final class HeaderBandUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testListHeaderRunsUpBehindTheBarAndTheTagChipsStartUnderIt() {
        let app = launch(scenario: "empty")
        let title = assertHeaderIsAtTop(in: app)

        // The band ends 22 pt under the title, and the chip row has 10 pt of padding: the chips
        // start 30.5 pt under the title on both platforms. With #94's gap it was a bar more.
        let chip = app.buttons["All"]
        XCTAssertTrue(chip.waitForExistence(timeout: 10))
        assertStartsUnderTheBand(chip, title: title, name: "The tag chips")

        assertPinkReachesTheWindowTop(in: app)
    }

    @MainActor
    func testDetailHeaderRunsUpBehindTheBarAndTheIngredientsStartUnderIt() {
        let app = launch(scenario: "recipeDetail")
        let title = assertHeaderIsAtTop(in: app)

        // The band ends 22 pt under the title, and the content has 20 pt of padding: the section
        // title starts 40.5 pt under the header title on both platforms.
        let ingredients = text("INGREDIENTS", in: app)
        XCTAssertTrue(ingredients.waitForExistence(timeout: 10))
        assertStartsUnderTheBand(ingredients, title: title, name: "The Ingredients section")

        // A short recipe used to size the scroll view to its content, centered in the window
        // with the window's background beside it (and on macOS no pink behind the toolbar).
        let window = app.windows.firstMatch.frame
        let indent = ingredients.frame.minX - window.minX
        XCTAssertTrue((0..<60).contains(indent), "The Ingredients section starts \(indent) pt from the window's left edge; the content belongs at the left margin")

        assertPinkReachesTheWindowTop(in: app)
    }

    // MARK: - Helpers

    /// Samples the window's screenshot 6 pt below its top, a quarter of the way across: clear
    /// of the traffic lights and toolbar buttons on macOS and of the clock and Dynamic Island
    /// on iOS. Only the pink behind the bar can make that pixel pink. On a Mac, XCTest's
    /// screenshots need the Screen Recording permission (see the README).
    @MainActor
    private func assertPinkReachesTheWindowTop(in app: XCUIApplication, file: StaticString = #filePath, line: UInt = #line) {
        let window = app.windows.firstMatch
        let color = pixel(at: CGPoint(x: window.frame.width / 4, y: 6), in: window)
        XCTAssertTrue(
            color.isPink,
            "The window top is \(color), not the header's pink: the pink should run up behind the \(bar(in: app).name)",
            file: file,
            line: line
        )
    }

    @MainActor
    private func assertStartsUnderTheBand(_ element: XCUIElement, title: CGRect, name: String, file: StaticString = #filePath, line: UInt = #line) {
        let gap = element.frame.minY - title.maxY
        XCTAssertTrue(
            (22..<50).contains(gap),
            "\(name) start \(gap) pt under the header title; they belong right under the pink band (22 pt under the title)",
            file: file,
            line: line
        )
    }
}

private extension RGB {
    /// PCColor.pink is (255, 61, 148); the screenshot's color space shifts it a little.
    var isPink: Bool {
        red > 220 && green < 110 && (110...190).contains(blue)
    }
}
