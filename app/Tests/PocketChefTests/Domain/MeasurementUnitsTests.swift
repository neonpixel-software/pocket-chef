@testable import PocketChef
import XCTest

final class MeasurementUnitsTests: XCTestCase {
    private func milliliters(_ unit: String, _ standard: VolumeStandard = .metric) -> Double? {
        guard case let .volume(milliliters)? = MeasurementUnits.kind(of: unit, standard: standard) else { return nil }
        return milliliters
    }

    private func grams(_ unit: String) -> Double? {
        guard case let .weight(grams)? = MeasurementUnits.kind(of: unit, standard: .metric) else { return nil }
        return grams
    }

    func testCupsAndSpoonsFollowTheVolumeStandard() throws {
        XCTAssertEqual(try XCTUnwrap(milliliters("cup", .usCustomary)), 236.588, accuracy: 0.001)
        XCTAssertEqual(milliliters("cup", .metric), 250)
        XCTAssertEqual(try XCTUnwrap(milliliters("tbsp", .usCustomary)), 14.787, accuracy: 0.001)
        XCTAssertEqual(milliliters("tbsp", .metric), 15)
        XCTAssertEqual(try XCTUnwrap(milliliters("tsp", .usCustomary)), 4.929, accuracy: 0.001)
        XCTAssertEqual(milliliters("tsp", .metric), 5)
    }

    func testPintsAreUSOrImperial() throws {
        XCTAssertEqual(try XCTUnwrap(milliliters("pint", .usCustomary)), 473.18, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(milliliters("pint", .metric)), 568.26, accuracy: 0.01)
    }

    func testMetricVolumes() {
        XCTAssertEqual(milliliters("ml"), 1)
        XCTAssertEqual(milliliters("cl"), 10)
        XCTAssertEqual(milliliters("dl"), 100)
        XCTAssertEqual(milliliters("l"), 1000)
        XCTAssertEqual(milliliters("Liter"), 1000)
    }

    func testWeights() throws {
        XCTAssertEqual(grams("g"), 1)
        XCTAssertEqual(grams("kg"), 1000)
        XCTAssertEqual(try XCTUnwrap(grams("oz")), 28.3495, accuracy: 0.0001)
        XCTAssertEqual(try XCTUnwrap(grams("lb")), 453.592, accuracy: 0.001)
    }

    /// A bare "oz" is a weight; only "fl oz" is a volume.
    func testFluidOuncesAreVolumeAndOuncesAreWeight() throws {
        XCTAssertEqual(try XCTUnwrap(milliliters("fl oz", .usCustomary)), 29.574, accuracy: 0.001)
        XCTAssertNotNil(grams("oz"))
    }

    func testPluralsCaseAndTrailingDots() {
        XCTAssertEqual(milliliters("Cups"), 250)
        XCTAssertEqual(milliliters("tablespoons"), 15)
        XCTAssertEqual(milliliters("Tbsp."), 15)
        XCTAssertEqual(grams("lbs"), 453.59237)
        XCTAssertEqual(grams("grams"), 1)
    }

    func testUnitsInTheOtherShippedLanguages() {
        XCTAssertEqual(milliliters("tazas"), 250)
        XCTAssertEqual(milliliters("cucharadas"), 15)
        XCTAssertEqual(milliliters("cuillères à soupe"), 15)
        XCTAssertEqual(milliliters("c. à c."), 5)
        XCTAssertEqual(milliliters("EL"), 15)
        XCTAssertEqual(milliliters("Teelöffel"), 5)
        XCTAssertEqual(milliliters("eetlepels"), 15)
        XCTAssertEqual(milliliters("kopje"), 250)
        XCTAssertEqual(grams("gramos"), 1)
    }

    /// Count and vague units have no size, so they must not be weighed.
    func testUnitsWithoutAFixedSizeAreNotMeasurements() {
        for unit in ["clove", "cloves", "can", "pinch", "handful", "large", "slice", ""] {
            XCTAssertNil(MeasurementUnits.kind(of: unit, standard: .metric), unit)
        }
    }
}
