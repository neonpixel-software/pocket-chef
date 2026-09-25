@testable import PocketChef
import XCTest

/// Verifies the String Catalog entries for the Equipment section (issue #82), read per language
/// from the compiled catalog (see LocalizationTestHelper).
final class LocalizedEquipmentStringsTests: XCTestCase {
    private let strings: [String: [String: String]] = [
        "Equipment": ["es": "Utensilios", "fr": "Ustensiles", "de": "Utensilien", "nl": "Benodigdheden"],
        "Add Equipment": [
            "es": "Añadir utensilio",
            "fr": "Ajouter un ustensile",
            "de": "Utensil hinzufügen",
            "nl": "Benodigdheid toevoegen",
        ],
        "Tool or cookware": [
            "es": "Utensilio o recipiente",
            "fr": "Ustensile ou récipient",
            "de": "Utensil oder Kochgeschirr",
            "nl": "Keukengerei of pan",
        ],
    ]

    func testEachEquipmentStringTranslatesPerLocale() {
        for (key, translations) in strings {
            for (languageCode, translated) in translations {
                XCTAssertEqual(
                    LocalizationTestHelper.translatedString(key, languageCode: languageCode),
                    translated,
                    "\(key) in \(languageCode)"
                )
            }
        }
    }
}
