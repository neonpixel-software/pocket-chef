@testable import PocketChef
import SwiftUI
import ViewInspector
import XCTest

final class IngredientLineTextTests: XCTestCase {
    private let saffron = IngredientLine(id: UUID(), rawText: "1 tsp saffron threads", amount: 1, unit: "tsp", ingredientName: "saffron threads")
    private let flour = IngredientLine(id: UUID(), rawText: "2 cups flour", amount: 2, unit: "cups", ingredientName: "flour")
    private let note = "Conversion not available"

    private func texts(_ view: IngredientLineText) throws -> [String] {
        try view.inspect().findAll(ViewType.Text.self).map { try $0.string() }
    }

    func testAsWrittenShowsOnlyTheLine() throws {
        XCTAssertEqual(try texts(IngredientLineText(ingredient: saffron, weight: nil)), ["1 tsp saffron threads"])
    }

    /// PLAN.md 11.2 acceptance: an ingredient absent from the density table shows the fallback
    /// note and its original measurement, not a fabricated number.
    func testAMissingDensityKeepsTheMeasurementAndSaysSo() throws {
        let texts = try texts(IngredientLineText(ingredient: saffron, weight: .unavailable(.noDensity)))

        XCTAssertEqual(texts, ["1 tsp saffron threads", note])
        XCTAssertFalse(texts.contains { $0.contains(" g") }, "no weight may be shown: \(texts)")
    }

    /// Nothing to convert is not a missing conversion: "2 eggs" and "salt to taste" get no note.
    func testLinesWithNothingToConvertGetNoNote() throws {
        let eggs = IngredientLine(id: UUID(), rawText: "2 eggs", amount: 2, unit: nil, ingredientName: "eggs")
        let salt = IngredientLine(id: UUID(), rawText: "salt to taste", amount: nil, unit: nil, ingredientName: "salt")

        XCTAssertEqual(try texts(IngredientLineText(ingredient: eggs, weight: .unavailable(.noMeasurementUnit))), ["2 eggs"])
        XCTAssertEqual(try texts(IngredientLineText(ingredient: salt, weight: .unavailable(.noAmount))), ["salt to taste"])
    }

    /// The note is a string literal, so SwiftUI looks it up in the catalog (a LocalizedStringKey);
    /// the ingredient line is user text and stays verbatim in every language.
    func testTheNoteIsLocalizedAndTheLineIsNot() throws {
        let german = Locale(identifier: "de")
        let texts = try IngredientLineText(ingredient: saffron, weight: .unavailable(.noDensity))
            .inspect().findAll(ViewType.Text.self).map { try $0.string(locale: german) }

        XCTAssertEqual(texts, ["1 tsp saffron threads", "Umrechnung nicht verfügbar"])
    }

    func testAConvertedLineShowsTheWeightAndTheOriginal() throws {
        let weight = IngredientWeightFormatter.format(grams: 250)

        let texts = try texts(IngredientLineText(ingredient: flour, weight: .grams(250)))

        XCTAssertEqual(texts, ["\(weight) flour", "2 cups flour"])
    }
}
