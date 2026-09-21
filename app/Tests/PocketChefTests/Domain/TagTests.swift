@testable import PocketChef
import XCTest

final class TagTests: XCTestCase {
    func testLocalizedDisplayNameReturnsSomeNonEmptyStringForEveryPreset() {
        for name in Tag.presetNames {
            let tag = Tag(id: UUID(), name: name, isPreset: true)
            XCTAssertFalse(tag.localizedDisplayName().isEmpty)
        }
    }

    func testLocalizedDisplayNameLeavesNonPresetTagsUntranslated() {
        let tag = Tag(id: UUID(), name: "Breakfast", isPreset: false)

        XCTAssertEqual(tag.localizedDisplayName(), "Breakfast")
    }

    func testLocalizedDisplayNameLeavesUnknownPresetNameUntranslated() {
        let tag = Tag(id: UUID(), name: "Some Future Preset", isPreset: true)

        XCTAssertEqual(tag.localizedDisplayName(), "Some Future Preset")
    }

    func testLocalizedDisplayNameLeavesCustomUserTagsExactlyAsTyped() {
        let tag = Tag(id: UUID(), name: "Grandma's Sunday Roast", isPreset: false)

        XCTAssertEqual(tag.localizedDisplayName(), "Grandma's Sunday Roast")
    }

    /// Verifies the String Catalog itself has a correct translation for every preset name in
    /// every supported language — catches a missing/typo'd catalog entry deterministically,
    /// independent of the test process's own system language (see LocalizationTestHelper).
    func testPresetNamesAreTranslatedInEveryCatalogLanguage() {
        let expected: [String: [String: String]] = [
            "Breakfast": ["es": "Desayuno", "fr": "Petit-déjeuner", "de": "Frühstück", "nl": "Ontbijt"],
            "Lunch": ["es": "Almuerzo", "fr": "Déjeuner", "de": "Mittagessen", "nl": "Lunch"],
            "Dinner": ["es": "Cena", "fr": "Dîner", "de": "Abendessen", "nl": "Diner"],
            "Dessert": ["es": "Postre", "fr": "Dessert", "de": "Nachtisch", "nl": "Toetje"],
            "Snack": ["es": "Merienda", "fr": "Collation", "de": "Snack", "nl": "Snack"],
        ]

        for (name, translations) in expected {
            for (languageCode, translated) in translations {
                XCTAssertEqual(
                    LocalizationTestHelper.translatedString(name, languageCode: languageCode),
                    translated,
                    "\(name) in \(languageCode)"
                )
            }
        }
    }
}
