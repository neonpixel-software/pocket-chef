@testable import PocketChef
import XCTest

final class IngredientWeightFormatterTests: XCTestCase {
    private let english = Locale(identifier: "en_US")

    /// The default measurement usage would show ounces in a US locale.
    func testKeepsGramsInAUSLocale() {
        XCTAssertEqual(IngredientWeightFormatter.format(grams: 125.04, locale: english), "125 g")
    }

    func testRoundsToWholeGramsFromTenGrams() {
        XCTAssertEqual(IngredientWeightFormatter.format(grams: 243.84, locale: english), "244 g")
        XCTAssertEqual(IngredientWeightFormatter.format(grams: 10.4, locale: english), "10 g")
    }

    func testKeepsOneDecimalBelowTenGrams() {
        XCTAssertEqual(IngredientWeightFormatter.format(grams: 5.69, locale: english), "5.7 g")
        XCTAssertEqual(IngredientWeightFormatter.format(grams: 3.0, locale: english), "3 g")
    }

    func testUsesTheLocalesDecimalSeparator() {
        XCTAssertEqual(IngredientWeightFormatter.format(grams: 5.69, locale: Locale(identifier: "de_DE")), "5,7 g")
    }
}
