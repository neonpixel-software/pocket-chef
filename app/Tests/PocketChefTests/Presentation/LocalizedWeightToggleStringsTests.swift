@testable import PocketChef
import XCTest

/// The recipe screen's as-written/weight toggle (Phase 11.1) needs a catalog entry in each
/// translated language. The translations still need the fluent-speaker pass (#65).
final class LocalizedWeightToggleStringsTests: XCTestCase {
    func testEveryToggleStringIsTranslated() {
        for key in ["Measurements", "As Written", "Weight"] {
            for languageCode in ["es", "fr", "de", "nl"] {
                let translated = LocalizationTestHelper.translatedString(key, languageCode: languageCode)
                XCTAssertNotNil(translated, "\(key) in \(languageCode)")
                XCTAssertNotEqual(translated, key, "\(key) in \(languageCode)")
            }
        }
    }

    func testSpotCheckGerman() {
        XCTAssertEqual(LocalizationTestHelper.translatedString("Weight", languageCode: "de"), "Gewicht")
    }
}
