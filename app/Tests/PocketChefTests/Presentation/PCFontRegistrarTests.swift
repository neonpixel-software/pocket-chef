import CoreText
@testable import PocketChef
import XCTest

final class PCFontRegistrarTests: XCTestCase {
    func testRegisterCustomFontsMakesEdoSZAvailable() {
        PCFontRegistrar.registerCustomFonts()

        let availableFamilies = CTFontManagerCopyAvailableFontFamilyNames() as? [String]

        XCTAssertTrue(availableFamilies?.contains("Edo SZ") ?? false)
    }

    func testRegisterCustomFontsIsSafeToCallRepeatedly() {
        PCFontRegistrar.registerCustomFonts()
        PCFontRegistrar.registerCustomFonts()

        let availableFamilies = CTFontManagerCopyAvailableFontFamilyNames() as? [String]
        XCTAssertTrue(availableFamilies?.contains("Edo SZ") ?? false)
    }
}
