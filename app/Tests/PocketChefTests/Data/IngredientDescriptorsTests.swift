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
}
