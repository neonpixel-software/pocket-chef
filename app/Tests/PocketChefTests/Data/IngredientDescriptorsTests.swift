@testable import PocketChef
import XCTest

final class IngredientDescriptorsTests: XCTestCase {
    func testRecognizesUnitsInEveryShippedLanguage() {
        for unit in ["cup", "tbsp", "g", "fl oz", "cucharada", "càs", "cuillère à soupe", "EL", "TL", "Prise", "eetlepel"] {
            XCTAssertTrue(IngredientDescriptors.isMeasurementUnit(unit), unit)
        }
    }

    func testRecognizesPluralsAndAbbreviationDots() {
        for unit in ["cups", "Tablespoons", "pinches", "tazas", "Tassen", "Zehen", "theelepels", "tsp.", "c. à s."] {
            XCTAssertTrue(IngredientDescriptors.isMeasurementUnit(unit), unit)
        }
    }

    func testIgnoresAccentsAndKnowsFrenchGr() {
        for unit in ["cuillere a soupe", "Cuillère À Soupe", "pincee", "gr", "gr."] {
            XCTAssertTrue(IngredientDescriptors.isMeasurementUnit(unit), unit)
        }
    }

    func testRejectsDescriptorsAndIngredients() {
        for unit in ["large", "yellow", "yellow onion", "egg", "pcs", "none", "item", "loaf pan"] {
            XCTAssertFalse(IngredientDescriptors.isMeasurementUnit(unit), unit)
        }
    }

    func testRemovesLeadingSizeWordsOnly() {
        XCTAssertEqual(IngredientDescriptors.removingSizeWords(from: "large egg"), "egg")
        XCTAssertEqual(IngredientDescriptors.removingSizeWords(from: "Extra-large eggs"), "eggs")
        XCTAssertEqual(IngredientDescriptors.removingSizeWords(from: "large yellow onion"), "yellow onion")
        XCTAssertEqual(IngredientDescriptors.removingSizeWords(from: "brown sugar"), "brown sugar")
        XCTAssertEqual(IngredientDescriptors.removingSizeWords(from: "egg, large"), "egg, large")
        XCTAssertEqual(IngredientDescriptors.removingSizeWords(from: "large"), "large")
    }

    func testFindsUnitAtStartOfText() {
        XCTAssertEqual(IngredientDescriptors.leadingUnit(in: "cup melted butter"), "cup")
        XCTAssertEqual(IngredientDescriptors.leadingUnit(in: "cuillères à soupe de sucre"), "cuillères à soupe")
        XCTAssertEqual(IngredientDescriptors.leadingUnit(in: "pincée de sel"), "pincée")
        XCTAssertNil(IngredientDescriptors.leadingUnit(in: "egg beaten"))
        XCTAssertNil(IngredientDescriptors.leadingUnit(in: ""))
    }

    func testFindsUnitAtEndOfText() {
        XCTAssertEqual(IngredientDescriptors.trailingUnit(in: "a pinch"), "pinch")
        XCTAssertNil(IngredientDescriptors.trailingUnit(in: "a few"))
    }

    func testIngredientAppearsInSourceAsWholeWords() {
        let source = "Pour 15 crêpes : 250 g de farine, 4 œufs et 1 pincée de sel. Faire un gâteau."

        XCTAssertTrue(IngredientDescriptors.appears(in: source, rawText: "250 g de farine", name: "farine"))
        XCTAssertTrue(IngredientDescriptors.appears(in: source, rawText: "4 oeufs", name: "œufs"))
        XCTAssertTrue(IngredientDescriptors.appears(in: source, rawText: "1 PINCEE  de sel", name: ""))
        XCTAssertFalse(IngredientDescriptors.appears(in: source, rawText: "eau", name: "eau"))
        XCTAssertFalse(IngredientDescriptors.appears(in: source, rawText: "", name: ""))
    }
}
