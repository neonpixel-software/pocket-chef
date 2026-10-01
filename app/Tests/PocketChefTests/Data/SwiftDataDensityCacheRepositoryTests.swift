@testable import PocketChef
import SwiftData
import XCTest

@MainActor
final class SwiftDataDensityCacheRepositoryTests: XCTestCase {
    private let date = Date(timeIntervalSince1970: 1_790_000_000)

    /// Held for the whole test: a context whose container is freed crashes SwiftData.
    private var container: ModelContainer?

    private func makeRepository() throws -> (SwiftDataDensityCacheRepository, ModelContext) {
        let container = try DensityStore.makeContainer(inMemory: true)
        self.container = container
        return (SwiftDataDensityCacheRepository(modelContext: container.mainContext), container.mainContext)
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    private func entry(_ name: String, _ gramsPerMilliliter: Double) -> DensityEntry {
        DensityEntry(ingredientName: name, gramsPerMilliliter: gramsPerMilliliter, lastModified: date)
    }

    func testANewCacheIsEmpty() throws {
        let (repository, _) = try makeRepository()

        XCTAssertTrue(try repository.isEmpty())
        XCTAssertNil(try repository.entry(forIngredientNamed: "flour"))
    }

    func testReplaceAllStoresTheEntries() throws {
        let (repository, _) = try makeRepository()

        try repository.replaceAll(with: [entry("flour", 0.53), entry("honey", 1.42)])

        XCTAssertFalse(try repository.isEmpty())
        XCTAssertEqual(try repository.entry(forIngredientNamed: "flour"), entry("flour", 0.53))
        XCTAssertEqual(try repository.entry(forIngredientNamed: "honey"), entry("honey", 1.42))
    }

    func testReplaceAllRemovesEntriesMissingFromTheNewSet() throws {
        let (repository, context) = try makeRepository()
        try repository.replaceAll(with: [entry("flour", 0.53), entry("honey", 1.42)])

        try repository.replaceAll(with: [entry("honey", 1.40)])

        XCTAssertNil(try repository.entry(forIngredientNamed: "flour"))
        XCTAssertEqual(try repository.entry(forIngredientNamed: "honey")?.gramsPerMilliliter, 1.40)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<DensityEntryModel>()), 1)
    }

    func testReplaceAllWithTheSameEntriesTwiceKeepsOneRowEach() throws {
        let (repository, context) = try makeRepository()
        let entries = [entry("flour", 0.53), entry("honey", 1.42)]

        try repository.replaceAll(with: entries)
        try repository.replaceAll(with: entries)

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<DensityEntryModel>()), 2)
    }

    func testReplaceAllKeepsOneEntryWhenTwoNamesShareALookupKey() throws {
        let (repository, context) = try makeRepository()

        try repository.replaceAll(with: [entry("caf\u{E9}", 1.0), entry("cafe\u{301}", 1.1)])

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<DensityEntryModel>()), 1)
        XCTAssertEqual(try repository.entry(forIngredientNamed: "Caf\u{E9}")?.gramsPerMilliliter, 1.1)
    }

    func testLookupMatchesCaseWhitespaceAndUnicodeForm() throws {
        let (repository, _) = try makeRepository()
        try repository.replaceAll(with: [entry("cr\u{E8}me fra\u{EE}che", 1.0)])

        XCTAssertNotNil(try repository.entry(forIngredientNamed: "  Cre\u{300}me Frai\u{302}che "))
    }

    func testLookupKeepsTheServerSpelling() throws {
        let (repository, _) = try makeRepository()
        try repository.replaceAll(with: [entry("All-Purpose Flour", 0.53)])

        XCTAssertEqual(try repository.entry(forIngredientNamed: "all-purpose flour")?.ingredientName, "All-Purpose Flour")
    }
}
