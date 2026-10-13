import XCTest

/// Takes the App Store screenshots (PLAN.md 12.2) in the UITestScenario.screenshots state and
/// attaches them to the test results. Skipped unless app/Scripts/take-screenshots.sh runs it,
/// which sets POCKETCHEF_SCREENSHOTS and the language (POCKETCHEF_SCREENSHOT_LANGUAGE), then
/// exports the attachments as PNGs.
final class AppStoreScreenshotsUITests: XCTestCase {
    private struct Language {
        let code: String
        let locale: String
        /// The recipe titles the test opens, as ScreenshotRecipes has them in this language.
        let detailTitle: String
        let weightTitle: String
        let link: String
    }

    private static let languages = [
        Language(code: "en", locale: "en_US", detailTitle: "Fluffy Pancakes", weightTitle: "Chocolate Chip Cookies", link: "https://example.com/recipes/shakshuka"),
        Language(code: "es", locale: "es_ES", detailTitle: "Tortitas esponjosas", weightTitle: "Galletas con chispas de chocolate", link: "https://example.com/recetas/shakshuka"),
        Language(code: "fr", locale: "fr_FR", detailTitle: "Pancakes moelleux", weightTitle: "Cookies aux pépites de chocolat", link: "https://example.com/recettes/chakchouka"),
        Language(code: "de", locale: "de_DE", detailTitle: "Fluffige Pancakes", weightTitle: "Chocolate-Chip-Cookies", link: "https://example.com/rezepte/shakshuka"),
        Language(code: "nl", locale: "nl_NL", detailTitle: "Luchtige pancakes", weightTitle: "Chocolate chip cookies", link: "https://example.com/recepten/shakshuka"),
    ]

    private var language: Language!

    override func setUpWithError() throws {
        let environment = ProcessInfo.processInfo.environment
        try XCTSkipUnless(environment["POCKETCHEF_SCREENSHOTS"] == "1", "Screenshots are taken by app/Scripts/take-screenshots.sh")
        let code = environment["POCKETCHEF_SCREENSHOT_LANGUAGE"] ?? "en"
        language = try XCTUnwrap(Self.languages.first { $0.code == code }, "No screenshot language \(code)")
        continueAfterFailure = false
    }

    @MainActor
    func testScreenshots() {
        let app = launch(showingWeights: false)
        snap("1-list", app)

        open(language.detailTitle, in: app)
        snap("2-detail", app)
        goBack(in: app)

        // Only English recipes have weights: the density table names ingredients in English.
        if language.code == "en" {
            app.terminate()
            let weightApp = launch(showingWeights: true)
            open(language.weightTitle, in: weightApp)
            snap("3-weights", weightApp)
            weightApp.terminate()
            _ = launch(showingWeights: false)
        }

        let current = XCUIApplication()
        tap(current.buttons["TagChip.Dessert"].firstMatch)
        snap("4-dessert", current)
        tap(current.buttons["TagChip.Dessert"].firstMatch)

        tap(current.buttons["RecipeList.add"].firstMatch)
        tap(current.buttons["AddRecipe.pasteLink"].firstMatch)
        let field = current.textFields["RecipeURLCapture.urlField"].firstMatch
        tap(field)
        field.typeText(language.link)
        snap("5-link", current)
    }

    // MARK: - Steps

    @MainActor
    private func launch(showingWeights: Bool) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-UITestScenario", "screenshots",
            "-AppleLanguages", "(\(language.code))",
            "-AppleLocale", language.locale,
            "-ApplePersistenceIgnoreState", "YES",
            // The detail screen's As Written / Weight choice (an @AppStorage).
            "-showsIngredientWeights", showingWeights ? "YES" : "NO",
        ]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["RecipeList"].waitForExistence(timeout: 15), "The recipe list is missing")
        return app
    }

    /// Taps the recipe's row: a button labeled with its title and then its tags.
    @MainActor
    private func open(_ title: String, in app: XCUIApplication) {
        tap(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", title)).firstMatch)
        // The detail screen's header shows the title once the list's row is gone.
        XCTAssertTrue(app.descendants(matching: .any)["RecipeList"].waitForNonExistence(timeout: 10), "\(title) didn't open")
    }

    @MainActor
    private func goBack(in app: XCUIApplication) {
        #if os(macOS)
        // The toolbar's back button, named after its symbol in every language.
        tap(app.toolbars.buttons["chevron.backward"].firstMatch)
        #else
        app.navigationBars.buttons.element(boundBy: 0).tap()
        #endif
        XCTAssertTrue(app.descendants(matching: .any)["RecipeList"].waitForExistence(timeout: 10), "The list didn't come back")
    }

    @MainActor
    private func tap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), "\(element) is missing")
        #if os(macOS)
        element.click()
        #else
        element.tap()
        #endif
    }

    /// Attaches the screen (iOS) or the app's window (macOS; 1440 × 900 pt, so 2880 × 1800 px on
    /// a Retina screen and 1440 × 900 on another, both App Store sizes) once animations settle.
    @MainActor
    private func snap(_ name: String, _ app: XCUIApplication) {
        Thread.sleep(forTimeInterval: 1.5)
        #if os(macOS)
        // The window cut out of a screenshot of the screen: the window's own screenshot()
        // failed every few runs ("Image creation failed").
        let window = app.windows.firstMatch.frame
        guard let screenPixels = XCUIScreen.main.screenshot().image.cgImage(forProposedRect: nil, context: nil, hints: nil),
              let screenPoints = NSScreen.screens.first?.frame.size else {
            return XCTFail("Couldn't take a screenshot of the main screen")
        }
        // XCUIScreen.main is the main screen (the one with the menu bar), so the window must be
        // all on it; cropping would otherwise quietly cut it short or take another screen's pixels.
        guard CGRect(origin: .zero, size: screenPoints).contains(window) else {
            return XCTFail("The window \(window) isn't all on the main screen (\(screenPoints))")
        }
        // The screenshot is in pixels; window frames are in points from the main screen's top left.
        // (The screenshot's NSImage size is in pixels too, so it can't give the scale.)
        let scale = CGFloat(screenPixels.width) / screenPoints.width
        let pixels = CGRect(x: window.minX * scale, y: window.minY * scale, width: window.width * scale, height: window.height * scale)
        guard let windowPixels = screenPixels.cropping(to: pixels) else {
            return XCTFail("Couldn't cut the window \(window) out of the screen")
        }
        guard let png = NSBitmapImageRep(cgImage: windowPixels).representation(using: .png, properties: [:]) else {
            return XCTFail("Couldn't encode the window as PNG")
        }
        let attachment = XCTAttachment(data: png, uniformTypeIdentifier: "public.png")
        #else
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot(), quality: .original)
        #endif
        attachment.name = "\(language.code)-\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
