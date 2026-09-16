import XCTest
@testable import PocketChef

final class RecipeRepositoryErrorTests: XCTestCase {
    func testRecipeNotFoundHasANonEmptyLocalizedDescription() {
        let error: Error = RecipeRepositoryError.recipeNotFound

        XCTAssertEqual(
            error.localizedDescription,
            "This recipe couldn't be found. It may have already been deleted."
        )
    }

    /// Verifies the String Catalog entry backing errorDescription translates in every
    /// supported language — see LocalizationTestHelper for why this reads the compiled
    /// catalog output directly rather than using String(localized:locale:).
    func testRecipeNotFoundDescriptionTranslatesPerLocale() {
        let translations = [
            "es": "No se pudo encontrar esta receta. Puede que ya se haya eliminado.",
            "fr": "Cette recette est introuvable. Elle a peut-être déjà été supprimée.",
            "de": "Dieses Rezept konnte nicht gefunden werden. Es wurde möglicherweise bereits gelöscht.",
            "nl": "Dit recept kon niet worden gevonden. Mogelijk is het al verwijderd."
        ]

        for (languageCode, translated) in translations {
            XCTAssertEqual(
                LocalizationTestHelper.translatedString(
                    "This recipe couldn't be found. It may have already been deleted.",
                    languageCode: languageCode
                ),
                translated,
                languageCode
            )
        }
    }
}
