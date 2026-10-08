@testable import PocketChef
import XCTest

/// Verifies the String Catalog entries for the form's Photos section (PLAN 13.2), read per
/// language from the compiled catalog (see LocalizationTestHelper).
final class LocalizedPhotoStringsTests: XCTestCase {
    private let strings: [String: [String: String]] = [
        "Photos": ["es": "Fotos", "fr": "Photos", "de": "Fotos", "nl": "Foto's"],
        "Make Cover": [
            "es": "Usar como portada",
            "fr": "Définir comme couverture",
            "de": "Als Titelbild verwenden",
            "nl": "Als omslag gebruiken",
        ],
        "Photo %lld of %lld": [
            "es": "Foto %lld de %lld",
            "fr": "Photo %lld sur %lld",
            "de": "Foto %lld von %lld",
            "nl": "Foto %lld van %lld",
        ],
        "A photo couldn't be added.": [
            "es": "No se pudo añadir una foto.",
            "fr": "Impossible d'ajouter une photo.",
            "de": "Ein Foto konnte nicht hinzugefügt werden.",
            "nl": "Een foto kon niet worden toegevoegd.",
        ],
    ]

    func testEachPhotoStringTranslatesPerLocale() {
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

    /// The camera permission prompt comes from the Info.plist, localized by InfoPlist.xcstrings.
    func testCameraUsageDescriptionTranslatesPerLocale() {
        let translations = [
            "es": "Pocket Chef usa la cámara para añadir fotos a tus recetas.",
            "fr": "Pocket Chef utilise l'appareil photo pour ajouter des photos à vos recettes.",
            "de": "Pocket Chef verwendet die Kamera, um Fotos zu deinen Rezepten hinzuzufügen.",
            "nl": "Pocket Chef gebruikt de camera om foto's aan je recepten toe te voegen.",
        ]
        for (languageCode, translated) in translations {
            guard let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
                  let bundle = Bundle(path: path) else {
                return XCTFail("no \(languageCode).lproj")
            }
            XCTAssertEqual(
                bundle.localizedString(forKey: "NSCameraUsageDescription", value: nil, table: "InfoPlist"),
                translated,
                languageCode
            )
        }
    }
}
