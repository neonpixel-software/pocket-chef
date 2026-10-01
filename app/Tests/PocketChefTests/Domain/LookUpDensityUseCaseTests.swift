@testable import PocketChef
import XCTest

@MainActor
final class LookUpDensityUseCaseTests: XCTestCase {
    func testExecuteReturnsTheCachedEntryMatchingTheName() throws {
        let container = try DensityStore.makeContainer(inMemory: true)
        let cache = SwiftDataDensityCacheRepository(modelContext: container.mainContext)
        let butter = DensityEntry(ingredientName: "butter", gramsPerMilliliter: 0.96, lastModified: Date(timeIntervalSince1970: 1_790_000_000))
        _ = try cache.apply([butter])

        let entry = try DefaultLookUpDensityUseCase(cacheRepository: cache).execute(ingredientName: " Butter")

        XCTAssertEqual(entry, butter)
    }

    func testExecuteReturnsNilForAnUnknownIngredient() throws {
        let container = try DensityStore.makeContainer(inMemory: true)
        let cache = SwiftDataDensityCacheRepository(modelContext: container.mainContext)

        XCTAssertNil(try DefaultLookUpDensityUseCase(cacheRepository: cache).execute(ingredientName: "saffron"))
    }
}
