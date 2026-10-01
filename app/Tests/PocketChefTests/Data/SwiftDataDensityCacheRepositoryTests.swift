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

    func testApplyToAnEmptyCacheAddsEveryEntry() throws {
        let (repository, _) = try makeRepository()

        let changes = try repository.apply([entry("flour", 0.53), entry("honey", 1.42)])

        XCTAssertEqual(changes, DensityCacheChanges(added: 2))
        XCTAssertFalse(try repository.isEmpty())
        XCTAssertEqual(try repository.entry(forIngredientNamed: "flour"), entry("flour", 0.53))
        XCTAssertEqual(try repository.entry(forIngredientNamed: "honey"), entry("honey", 1.42))
    }

    func testApplyRemovesEntriesTheServerNoLongerHas() throws {
        let (repository, context) = try makeRepository()
        _ = try repository.apply([entry("flour", 0.53), entry("honey", 1.42)])

        let changes = try repository.apply([entry("honey", 1.42)])

        XCTAssertEqual(changes, DensityCacheChanges(removed: 1))
        XCTAssertNil(try repository.entry(forIngredientNamed: "flour"))
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<DensityEntryModel>()), 1)
    }

    func testApplyUpdatesAnEntryChangedOnTheServer() throws {
        let (repository, _) = try makeRepository()
        _ = try repository.apply([entry("flour", 0.53), entry("honey", 1.42)])
        let newerHoney = DensityEntry(ingredientName: "Honey", gramsPerMilliliter: 1.40, lastModified: date.addingTimeInterval(60))

        let changes = try repository.apply([entry("flour", 0.53), newerHoney])

        XCTAssertEqual(changes, DensityCacheChanges(updated: 1))
        XCTAssertEqual(try repository.entry(forIngredientNamed: "honey"), newerHoney)
    }

    func testApplyAddsAnEntryNewOnTheServer() throws {
        let (repository, _) = try makeRepository()
        _ = try repository.apply([entry("flour", 0.53)])

        let changes = try repository.apply([entry("flour", 0.53), entry("maple syrup", 1.33)])

        XCTAssertEqual(changes, DensityCacheChanges(added: 1))
        XCTAssertEqual(try repository.entry(forIngredientNamed: "Maple Syrup")?.gramsPerMilliliter, 1.33)
    }

    func testApplyingTheSameEntriesAgainChangesNothing() throws {
        let (repository, context) = try makeRepository()
        let entries = [entry("flour", 0.53), entry("honey", 1.42)]
        _ = try repository.apply(entries)

        let changes = try repository.apply(entries)

        XCTAssertTrue(changes.isEmpty)
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<DensityEntryModel>()), 2)
    }

    func testApplyKeepsOneEntryWhenTwoNamesShareALookupKey() throws {
        let (repository, context) = try makeRepository()

        _ = try repository.apply([entry("caf\u{E9}", 1.0), entry("cafe\u{301}", 1.1)])

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<DensityEntryModel>()), 1)
        XCTAssertEqual(try repository.entry(forIngredientNamed: "Caf\u{E9}")?.gramsPerMilliliter, 1.1)
    }

    func testLookupMatchesCaseWhitespaceAndUnicodeForm() throws {
        let (repository, _) = try makeRepository()
        _ = try repository.apply([entry("cr\u{E8}me fra\u{EE}che", 1.0)])

        XCTAssertNotNil(try repository.entry(forIngredientNamed: "  Cre\u{300}me Frai\u{302}che "))
    }

    func testLookupKeepsTheServerSpelling() throws {
        let (repository, _) = try makeRepository()
        _ = try repository.apply([entry("All-Purpose Flour", 0.53)])

        XCTAssertEqual(try repository.entry(forIngredientNamed: "all-purpose flour")?.ingredientName, "All-Purpose Flour")
    }
}
