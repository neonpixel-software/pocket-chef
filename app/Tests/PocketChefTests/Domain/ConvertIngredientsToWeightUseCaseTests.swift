@testable import PocketChef
import SwiftData
import XCTest

@MainActor
final class ConvertIngredientsToWeightUseCaseTests: XCTestCase {
    private var container: ModelContainer?

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private func makeUseCase(_ entries: [DensityEntry], standard: VolumeStandard = .usCustomary) throws -> DefaultConvertIngredientsToWeightUseCase {
        let container = try DensityStore.makeContainer(inMemory: true)
        self.container = container
        let cache = SwiftDataDensityCacheRepository(modelContext: container.mainContext)
        _ = try cache.apply(entries)
        return DefaultConvertIngredientsToWeightUseCase(cacheRepository: cache, standard: standard)
    }

    private func entry(_ name: String, _ gramsPerMilliliter: Double) -> DensityEntry {
        DensityEntry(ingredientName: name, gramsPerMilliliter: gramsPerMilliliter, lastModified: Date(timeIntervalSince1970: 1))
    }

    private func line(_ rawText: String, _ amount: Double?, _ unit: String?, _ name: String?) -> IngredientLine {
        IngredientLine(id: UUID(), rawText: rawText, amount: amount, unit: unit, ingredientName: name)
    }

    /// PLAN.md 11.1 acceptance: toggling shows correct gram values for ingredients with density
    /// data. Densities are the USDA seed values.
    func testConvertsARecipeUsingTheCachedDensities() throws {
        let useCase = try makeUseCase([
            entry("all-purpose flour", 0.528344104716297),
            entry("granulated sugar", 0.845351),
            entry("milk", 1.030684),
        ])
        let flour = line("2 cups all-purpose flour", 2, "cups", "all-purpose flour")
        let sugar = line("1/2 cup sugar", 0.5, "cup", "granulated sugar")
        let milk = line("1 cup milk", 1, "cup", "milk")
        let eggs = line("2 eggs", 2, nil, "eggs")
        let saffron = line("1 tsp saffron", 1, "tsp", "saffron")

        let weights = useCase.execute([flour, sugar, milk, eggs, saffron])

        XCTAssertEqual(weights.count, 5)
        guard case let .grams(flourGrams)? = weights[flour.id],
              case let .grams(sugarGrams)? = weights[sugar.id],
              case let .grams(milkGrams)? = weights[milk.id] else { return XCTFail("Expected grams for flour, sugar and milk: \(weights)") }
        XCTAssertEqual(flourGrams, 250.0, accuracy: 0.1)
        XCTAssertEqual(sugarGrams, 100.0, accuracy: 0.1)
        XCTAssertEqual(milkGrams, 243.8, accuracy: 0.1)
        XCTAssertEqual(weights[eggs.id], .unavailable(.noMeasurementUnit))
        XCTAssertEqual(weights[saffron.id], .unavailable(.noDensity))
    }

    func testWithAnEmptyCacheOnlyWeightUnitsConvert() throws {
        let useCase = try makeUseCase([])
        let flour = line("1 cup flour", 1, "cup", "flour")
        let butter = line("100 g butter", 100, "g", "butter")

        let weights = useCase.execute([flour, butter])

        XCTAssertEqual(weights[flour.id], .unavailable(.noDensity))
        XCTAssertEqual(weights[butter.id], .grams(100))
    }
}

final class DensityNameIndexTests: XCTestCase {
    private let index = DensityNameIndex([
        DensityEntry(ingredientName: "all-purpose flour", gramsPerMilliliter: 0.53, lastModified: .now),
        DensityEntry(ingredientName: "walnuts", gramsPerMilliliter: 0.5, lastModified: .now),
        DensityEntry(ingredientName: "butter", gramsPerMilliliter: 0.96, lastModified: .now),
        DensityEntry(ingredientName: "brown sugar", gramsPerMilliliter: 0.93, lastModified: .now),
    ])

    func testMatchesTheExactNameIgnoringCaseAndSpaces() {
        XCTAssertEqual(index.entry(forIngredientNamed: " Butter ")?.ingredientName, "butter")
    }

    func testAHyphenAndASpaceAreTheSame() {
        XCTAssertEqual(index.entry(forIngredientNamed: "all purpose flour")?.ingredientName, "all-purpose flour")
        XCTAssertEqual(index.entry(forIngredientNamed: "All-Purpose Flour")?.ingredientName, "all-purpose flour")
    }

    func testSingularAndPluralAreTheSame() {
        XCTAssertEqual(index.entry(forIngredientNamed: "walnut")?.ingredientName, "walnuts")
        XCTAssertEqual(index.entry(forIngredientNamed: "butters")?.ingredientName, "butter")
    }

    /// No guessing (PLAN.md): a different ingredient is never substituted.
    func testDoesNotMatchADifferentOrMoreSpecificIngredient() {
        XCTAssertNil(index.entry(forIngredientNamed: "unsalted butter"))
        XCTAssertNil(index.entry(forIngredientNamed: "sugar"))
        XCTAssertNil(index.entry(forIngredientNamed: "flour"))
        XCTAssertNil(index.entry(forIngredientNamed: ""))
    }
}
