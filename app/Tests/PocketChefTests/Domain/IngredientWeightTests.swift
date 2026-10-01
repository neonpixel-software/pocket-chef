@testable import PocketChef
import XCTest

final class IngredientWeightTests: XCTestCase {
    /// USDA SR Legacy values from the seed: 1 cup all-purpose flour = 125 g.
    private let flour = DensityEntry(ingredientName: "all-purpose flour", gramsPerMilliliter: 0.528344104716297, lastModified: .now)
    private let butter = DensityEntry(ingredientName: "butter", gramsPerMilliliter: 0.959585, lastModified: .now)

    private func line(_ amount: Double?, _ unit: String?, _ name: String? = "x") -> IngredientLine {
        IngredientLine(id: UUID(), rawText: "", amount: amount, unit: unit, ingredientName: name)
    }

    private func grams(_ weight: IngredientWeight) throws -> Double {
        guard case let .grams(grams) = weight else {
            XCTFail("Expected grams, got \(weight)")
            return 0
        }
        return grams
    }

    func testOneUSCupOfFlourWeighs125Grams() throws {
        let weight = IngredientWeight.of(line(1, "cup"), density: flour, standard: .usCustomary)

        XCTAssertEqual(try grams(weight), 125.0, accuracy: 0.1)
    }

    func testAMetricCupIsLargerThanAUSCup() throws {
        let weight = IngredientWeight.of(line(1, "cup"), density: flour, standard: .metric)

        XCTAssertEqual(try grams(weight), 132.1, accuracy: 0.1)
    }

    func testFractionalSpoons() throws {
        let weight = IngredientWeight.of(line(2.5, "tbsp"), density: butter, standard: .metric)

        XCTAssertEqual(try grams(weight), 2.5 * 15 * 0.959585, accuracy: 0.0001)
    }

    func testWeightUnitsConvertWithoutADensity() throws {
        XCTAssertEqual(try grams(IngredientWeight.of(line(200, "g"), density: nil, standard: .usCustomary)), 200)
        XCTAssertEqual(try grams(IngredientWeight.of(line(8, "oz"), density: nil, standard: .usCustomary)), 226.8, accuracy: 0.1)
        XCTAssertEqual(try grams(IngredientWeight.of(line(1.5, "kg"), density: nil, standard: .usCustomary)), 1500)
    }

    func testAVolumeWithoutADensityIsNotGuessed() {
        XCTAssertEqual(IngredientWeight.of(line(1, "cup"), density: nil, standard: .usCustomary), .unavailable(.noDensity))
    }

    func testLinesWithoutAnAmountOrAMeasurementUnitStayAsWritten() {
        XCTAssertEqual(IngredientWeight.of(line(nil, "cup"), density: flour, standard: .usCustomary), .unavailable(.noAmount))
        XCTAssertEqual(IngredientWeight.of(line(0, "cup"), density: flour, standard: .usCustomary), .unavailable(.noAmount))
        XCTAssertEqual(IngredientWeight.of(line(3, nil), density: flour, standard: .usCustomary), .unavailable(.noMeasurementUnit))
        XCTAssertEqual(IngredientWeight.of(line(2, "cloves"), density: flour, standard: .usCustomary), .unavailable(.noMeasurementUnit))
    }
}
