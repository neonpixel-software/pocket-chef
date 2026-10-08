@testable import PocketChef
import XCTest

/// Verifies the String Catalog entries for the welcome guide (PLAN 14.1), read per language
/// from the compiled catalog (see LocalizationTestHelper). The texts are drafts until the
/// native-speaker review.
final class LocalizedWelcomeGuideStringsTests: XCTestCase {
    private let strings: [String: [String: String]] = [
        "Welcome to Pocket Chef": [
            "es": "Te damos la bienvenida a Pocket Chef",
            "fr": "Bienvenue dans Pocket Chef",
            "de": "Willkommen bei Pocket Chef",
            "nl": "Welkom bij Pocket Chef",
        ],
        "Add a Recipe": ["es": "Añadir una receta", "fr": "Ajouter une recette", "de": "Ein Rezept hinzufügen", "nl": "Een recept toevoegen"],
        "Cook From It": ["es": "Cocina con ella", "fr": "Cuisinez avec", "de": "Damit kochen", "nl": "Ermee koken"],
        "Make It Yours": ["es": "A tu gusto", "fr": "À votre goût", "de": "Nach deinem Geschmack", "nl": "Naar jouw smaak"],
        "Choose + and then Enter Manually to fill in a recipe yourself.": [
            "es": "Elige + y luego Introducir manualmente para rellenar tú la receta.",
            "fr": "Choisissez + puis Saisir manuellement pour remplir la recette vous-même.",
            "de": "Wähle + und dann Manuell eingeben, um ein Rezept selbst auszufüllen.",
            "nl": "Kies + en dan Handmatig invoeren om zelf een recept in te vullen.",
        ],
        // French puts a no-break space before a colon, so the colon never starts a line.
        "In Settings you can change:": [
            "es": "En Ajustes puedes cambiar:",
            "fr": "Dans Réglages, vous pouvez modifier\u{00A0}:",
            "de": "In den Einstellungen kannst du ändern:",
            "nl": "In Instellingen kun je dit aanpassen:",
        ],
        "Skip": ["es": "Omitir", "fr": "Passer", "de": "Überspringen", "nl": "Overslaan"],
        "Next": ["es": "Siguiente", "fr": "Suivant", "de": "Weiter", "nl": "Volgende"],
        "Get Started": ["es": "Empezar", "fr": "Commencer", "de": "Los geht's", "nl": "Aan de slag"],
        "Previous Page": ["es": "Página anterior", "fr": "Page précédente", "de": "Vorherige Seite", "nl": "Vorige pagina"],
        "Next Page": ["es": "Página siguiente", "fr": "Page suivante", "de": "Nächste Seite", "nl": "Volgende pagina"],
        "Page %lld of %lld": ["es": "Página %lld de %lld", "fr": "Page %lld sur %lld", "de": "Seite %lld von %lld", "nl": "Pagina %lld van %lld"],
        "Help": ["es": "Ayuda", "fr": "Aide", "de": "Hilfe", "nl": "Help"],
        "Show Welcome Guide": [
            "es": "Mostrar la guía de bienvenida",
            "fr": "Afficher le guide de bienvenue",
            "de": "Willkommensanleitung anzeigen",
            "nl": "Welkomstgids tonen",
        ],
        "Welcome Guide": ["es": "Guía de bienvenida", "fr": "Guide de bienvenue", "de": "Willkommensanleitung", "nl": "Welkomstgids"],
    ]

    func testEachGuideStringTranslatesPerLocale() {
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

    /// Every text of every page is translated, in both versions of page 2: none comes back as
    /// the English key. ("Help" is the same in Dutch, but it isn't on a page.)
    func testEveryPageTextIsTranslated() {
        let pages = WelcomeGuidePage.pages(isCaptureAvailable: true) + [WelcomeGuidePage.pages(isCaptureAvailable: false)[1]]
        let texts = pages.flatMap { [$0.title, $0.body] + $0.items + [$0.note].compactMap(\.self) }
        for text in texts {
            for languageCode in ["es", "fr", "de", "nl"] {
                let translated = LocalizationTestHelper.translatedString(text, languageCode: languageCode)
                XCTAssertNotNil(translated, "\(languageCode) catalog")
                XCTAssertNotEqual(translated, text, "\"\(text)\" has no \(languageCode) translation")
            }
        }
    }
}
