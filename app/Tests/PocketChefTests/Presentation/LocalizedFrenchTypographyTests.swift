import XCTest

/// French puts a no-break space (U+00A0) before : ; ? ! and » and after «, so the mark never
/// starts a line on its own. A regular space there is easy to type and hard to see (#165).
final class LocalizedFrenchTypographyTests: XCTestCase {
    func testFrenchPunctuationUsesNoBreakSpaces() throws {
        for table in ["Localizable", "InfoPlist"] {
            let translations = try frenchTranslations(in: table)
            XCTAssertFalse(translations.isEmpty, "No French \(table) strings found")

            for (key, value) in translations {
                for space in [" :", " ;", " ?", " !", " »", "« "] where value.contains(space) {
                    XCTFail("\(table) fr for \"\(key)\" has a regular space in \"\(space)\": \(value)")
                }
            }
        }
    }

    /// The compiled String Catalog's French table, as key → value.
    private func frenchTranslations(in table: String) throws -> [String: String] {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: table, withExtension: "strings", subdirectory: nil, localization: "fr"),
            "fr.lproj/\(table).strings is missing from the app"
        )
        return try XCTUnwrap(NSDictionary(contentsOf: url) as? [String: String])
    }
}
