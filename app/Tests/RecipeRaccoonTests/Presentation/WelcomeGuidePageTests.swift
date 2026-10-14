@testable import RecipeRaccoon
import XCTest

/// The guide's text (14.1), checked as plain data.
final class WelcomeGuidePageTests: XCTestCase {
    func testWithCaptureAddARecipeOffersAllThreeWays() {
        let page = WelcomeGuidePage.pages(isCaptureAvailable: true)[1]

        XCTAssertEqual(page.id, .addRecipe)
        XCTAssertEqual(page.title, "Add a Recipe")
        XCTAssertEqual(page.body, "Choose + and then one of three ways:")
        XCTAssertEqual(page.items, [
            "Type It: type or paste a recipe's text.",
            "Paste a Link: the address of a recipe's web page.",
            "Enter Manually: fill in the recipe yourself.",
        ])
        XCTAssertEqual(
            page.note,
            "For Type It and Paste a Link, Apple Intelligence reads the recipe on your device. You always check it before it's saved."
        )
    }

    /// Without Apple Intelligence the + menu's Type It and Paste a Link only lead to an alert,
    /// so the guide doesn't offer them.
    func testWithoutCaptureAddARecipeOnlyOffersEnteringByHand() {
        let page = WelcomeGuidePage.pages(isCaptureAvailable: false)[1]

        XCTAssertEqual(page.id, .addRecipe)
        XCTAssertEqual(page.body, "Choose + and then Enter Manually to fill in a recipe yourself.")
        XCTAssertEqual(page.items, [])
        XCTAssertEqual(
            page.note,
            "Type It and Paste a Link read a recipe for you with Apple Intelligence, which isn't available on this device."
        )
    }

    func testTheOtherPagesDontDependOnCapture() {
        let with = WelcomeGuidePage.pages(isCaptureAvailable: true)
        let without = WelcomeGuidePage.pages(isCaptureAvailable: false)

        for index in [0, 2, 3] {
            XCTAssertEqual(with[index], without[index])
        }
        XCTAssertEqual(with.map(\.title), ["Welcome to Recipe Raccoon", "Add a Recipe", "Cook From It", "Make It Yours"])
    }

    func testTheVoiceOverLabelReadsTheWholePageThenItsPosition() {
        let page = WelcomeGuidePage.pages(isCaptureAvailable: false)[1]

        XCTAssertEqual(
            page.accessibilityLabel(at: 1, of: 4),
            "Add a Recipe, Choose + and then Enter Manually to fill in a recipe yourself. "
                + "Type It and Paste a Link read a recipe for you with Apple Intelligence, which isn't available on this device. Page 2 of 4"
        )
    }

    /// The first page shows the app icon, so the image WelcomeGuidePageView draws for it must
    /// ship in the app; the other pages keep their symbols.
    func testTheWelcomePageShowsTheAppIcon() {
        let pages = WelcomeGuidePage.pages(isCaptureAvailable: true)

        XCTAssertEqual(pages[0].artwork, .appIcon)
        XCTAssertEqual(pages.dropFirst().map(\.artwork), [.symbol("plus"), .symbol("frying.pan"), .symbol("gearshape")])
        #if os(macOS)
        XCTAssertNotNil(NSImage(named: "WelcomeAppIcon"))
        #else
        XCTAssertNotNil(UIImage(named: "WelcomeAppIcon"))
        #endif
    }

    /// Only the last page offers the choice between this device and iCloud.
    func testOnlyTheSettingsPageOffersTheStorageChoice() {
        let pages = WelcomeGuidePage.pages(isCaptureAvailable: true)

        XCTAssertEqual(pages.map(\.offersStorageChoice), [false, false, false, true])
        XCTAssertEqual(pages.last?.id, .settings)
    }

    func testTheSettingsPageNamesEachSettingAndWhereSettingsIs() {
        let page = WelcomeGuidePage.pages(isCaptureAvailable: true)[3]

        XCTAssertEqual(page.items, [
            "Theme and Language: light or dark, and the language Recipe Raccoon uses.",
            "Cups and Spoons: US or metric sizes, used for weights.",
            "Ingredient Densities: they update daily, and you can refresh them any time.",
        ])
        #if os(macOS)
        XCTAssertEqual(page.note, "Settings is in the Recipe Raccoon menu (⌘,). You can open this guide again there, or from the Help menu.")
        #else
        XCTAssertEqual(page.note, "Settings is the gear at the top of your recipes. You can open this guide again there too.")
        #endif
    }
}
