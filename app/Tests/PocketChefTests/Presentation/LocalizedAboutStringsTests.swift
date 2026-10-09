@testable import PocketChef
import XCTest

/// Verifies the String Catalog entries for the About page (PLAN 14.2), read per language from
/// the compiled catalog (see LocalizationTestHelper). The texts are drafts until the
/// native-speaker review (#156).
final class LocalizedAboutStringsTests: XCTestCase {
    private let strings: [String: [String: String]] = [
        "About Pocket Chef": ["es": "Acerca de Pocket Chef", "fr": "À propos de Pocket Chef", "de": "Über Pocket Chef", "nl": "Over Pocket Chef"],
        "No Tracking": ["es": "Sin rastreo", "fr": "Aucun suivi", "de": "Kein Tracking", "nl": "Geen tracking"],
        "View the Code on GitHub": ["es": "Ver el código en GitHub", "fr": "Voir le code sur GitHub", "de": "Code auf GitHub ansehen", "nl": "Code bekijken op GitHub"],
        "Report an Issue": ["es": "Informar de un problema", "fr": "Signaler un problème", "de": "Problem melden", "nl": "Probleem melden"],
        // French puts a no-break space before a colon, so the colon never starts a line.
        "The app only goes online to:": [
            "es": "La app solo se conecta a internet para:",
            "fr": "L'app ne se connecte à Internet que pour\u{00A0}:",
            "de": "Die App geht nur für Folgendes online:",
            "nl": "De app gaat alleen online om:",
        ],
        "Version %@ (%@)": ["es": "Versión %@ (%@)", "fr": "Version %@ (%@)", "de": "Version %@ (%@)", "nl": "Versie %@ (%@)"],
    ]

    /// Every text on the page, which must not come back as the English key. ("Open Source" and
    /// the version line read the same in some languages, so they're only in `strings`.)
    private let pageTexts = [
        "The Idea",
        "Recipe sites bury the recipe under ads, pop-ups and life stories. Pocket Chef keeps just the recipe: type it, paste it or link it, check it once, and cook from a clean page.",
        "Pocket Chef is open source under the MIT license. Anyone can read the code, check what the app does, and build it themselves.",
        "No account, no ads, no analytics, no tracking.",
        "Your recipes stay on this device, or in your own iCloud if you turn on sync.",
        "Recipe capture runs on your device.",
        "Fetch the recipe from a link you paste. That website sees the visit, as it would in a browser.",
        "Sync your recipes through your own iCloud, if you turn it on.",
        "Download ingredient densities from Pocket Chef's server. The app sends it nothing about you or your recipes.",
        "Reporting an issue needs a free GitHub account.",
        "Made by NeonPixel",
    ]

    func testEachAboutStringTranslatesPerLocale() {
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

    func testEveryPageTextIsTranslated() {
        for text in pageTexts + Array(strings.keys) where text != "Version %@ (%@)" {
            for languageCode in ["es", "fr", "de", "nl"] {
                let translated = LocalizationTestHelper.translatedString(text, languageCode: languageCode)
                XCTAssertNotNil(translated, "\(languageCode) catalog")
                XCTAssertNotEqual(translated, text, "\"\(text)\" has no \(languageCode) translation")
            }
        }
    }
}
