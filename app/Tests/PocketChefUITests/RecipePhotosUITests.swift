import XCTest

/// Recipe photos as they render (13.3): the cover in the list row, the detail gallery, and
/// Make Cover in the form. The recipeWithPhotos scenarios seed photos in solid red (the cover),
/// green and blue (UITestScenario.photoColors), so a screenshot pixel shows which photo is
/// where. The photo picker and the camera are system UI and get a manual check instead.
final class RecipePhotosUITests: XCTestCase {
    private enum PhotoColor: String {
        case red, green, blue, other
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    @MainActor
    func testListRowShowsTheCoverThumbnail() {
        let app = launch(scenario: "recipeWithPhotos")

        let row = app.buttons["Rainbow Salad"]
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        // The 56 pt thumbnail sits inside the row's 16 pt padding, so its center is 44 pt in.
        let window = app.windows.firstMatch
        let center = CGPoint(x: row.frame.minX + 44 - window.frame.minX, y: row.frame.midY - window.frame.minY)
        XCTAssertEqual(photoColor(pixel(at: center, in: window)), .red, "The row doesn't show the red cover photo")
    }

    @MainActor
    func testDetailGalleryStartsOnTheCoverAndLabelsItsPages() {
        let app = launch(scenario: "recipeWithPhotosDetail")

        let cover = galleryPage("Cover photo", in: app)
        XCTAssertTrue(cover.waitForExistence(timeout: 10))
        XCTAssertEqual(photoColor(pixel(atCenterOf: cover, in: app)), .red, "The gallery doesn't start on the red cover")

        #if os(iOS)
        // A swipe doesn't reach the app on GitHub's macOS runner, and the Mac's arrow buttons
        // need a click, so turning pages is checked on iOS only.
        cover.swipeLeft()
        let second = galleryPage("Photo 2 of 3", in: app)
        XCTAssertTrue(second.wait(for: \.isHittable, toEqual: true, timeout: 5), "Swiping didn't turn to the second photo")
        XCTAssertEqual(photoColor(pixel(atCenterOf: second, in: app)), .green, "The second page isn't the green photo")
        #endif
    }

    /// Long-pressing a thumbnail for its context menu is a touch interaction, and clicks don't
    /// reach the app on GitHub's macOS runner, so this runs on iOS. The form's unit tests cover
    /// the same actions on both platforms through the accessibility actions.
    @MainActor
    func testMakeCoverInTheFormChangesTheGalleryCover() throws {
        #if os(macOS)
        throw XCTSkip("Needs a long press, which the macOS runner can't deliver")
        #else
        let app = launch(scenario: "recipeWithPhotosDetail")
        XCTAssertTrue(galleryPage("Cover photo", in: app).waitForExistence(timeout: 10))

        app.buttons["Edit"].tap()
        let thumbnails = app.descendants(matching: .any).matching(identifier: "RecipeFormPhoto")
        let second = thumbnails.matching(NSPredicate(format: "label == %@", "Photo 2 of 3")).firstMatch
        XCTAssertTrue(second.waitForExistence(timeout: 10))
        second.press(forDuration: 1)
        let makeCover = app.buttons["Make Cover"]
        XCTAssertTrue(makeCover.waitForExistence(timeout: 5), "The thumbnail's context menu didn't open")
        makeCover.tap()

        let newCover = thumbnails.matching(NSPredicate(format: "label == %@", "Cover photo")).firstMatch
        XCTAssertTrue(newCover.waitForExistence(timeout: 5))
        XCTAssertEqual(photoColor(pixel(atCenterOf: newCover, in: app)), .green, "Make Cover didn't move the green photo first")

        app.buttons["Save"].tap()
        let galleryCover = galleryPage("Cover photo", in: app)
        XCTAssertTrue(galleryCover.wait(for: \.isHittable, toEqual: true, timeout: 10), "The form didn't close")
        XCTAssertEqual(photoColor(pixel(atCenterOf: galleryCover, in: app)), .green, "The saved gallery doesn't start on the green photo")
        #endif
    }

    // MARK: - Helpers

    @MainActor
    private func galleryPage(_ label: String, in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(identifier: "RecipeGalleryPhoto").matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    /// Which seeded photo a pixel belongs to: the screenshot's color space shifts the colors a
    /// little, so the strongest channel decides, by a clear margin.
    private func photoColor(_ color: RGB) -> PhotoColor {
        let channels: [(PhotoColor, Int)] = [(.red, color.red), (.green, color.green), (.blue, color.blue)]
        let sorted = channels.sorted { $0.1 > $1.1 }
        return sorted[0].1 - sorted[1].1 > 80 ? sorted[0].0 : .other
    }
}
