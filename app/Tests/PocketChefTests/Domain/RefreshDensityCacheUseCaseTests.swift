@testable import PocketChef
import XCTest

private final class StubDensityEntryRemoteSource: DensityEntryRemoteSource, @unchecked Sendable {
    var result: Result<[DensityEntry], Error>
    private(set) var fetchCount = 0

    init(result: Result<[DensityEntry], Error>) {
        self.result = result
    }

    func fetchAll() async throws -> [DensityEntry] {
        fetchCount += 1
        return try result.get()
    }
}

private final class FakeDensityCacheRepository: DensityCacheRepository {
    var entries: [DensityEntry] = []

    func replaceAll(with entries: [DensityEntry]) throws {
        self.entries = entries
    }

    func entry(forIngredientNamed name: String) throws -> DensityEntry? {
        entries.first { $0.id == DensityEntry.lookupKey(for: name) }
    }

    func isEmpty() throws -> Bool {
        entries.isEmpty
    }
}

@MainActor
final class RefreshDensityCacheUseCaseTests: XCTestCase {
    private let flour = DensityEntry(ingredientName: "flour", gramsPerMilliliter: 0.53, lastModified: Date(timeIntervalSince1970: 1))
    private let honey = DensityEntry(ingredientName: "honey", gramsPerMilliliter: 1.42, lastModified: Date(timeIntervalSince1970: 2))

    func testExecuteReplacesTheCacheWithTheFetchedEntries() async throws {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let useCase = DefaultRefreshDensityCacheUseCase(
            remoteSource: StubDensityEntryRemoteSource(result: .success([honey])),
            cacheRepository: cache
        )

        try await useCase.execute()

        XCTAssertEqual(cache.entries, [honey])
    }

    func testExecuteLeavesTheCacheAloneWhenTheFetchFails() async {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let useCase = DefaultRefreshDensityCacheUseCase(
            remoteSource: StubDensityEntryRemoteSource(result: .failure(URLError(.notConnectedToInternet))),
            cacheRepository: cache
        )

        do {
            try await useCase.execute()
            XCTFail("Expected the fetch error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
        XCTAssertEqual(cache.entries, [flour])
    }

    func testExecuteIfCacheEmptyFetchesWhenNothingIsCached() async throws {
        let cache = FakeDensityCacheRepository()
        let remote = StubDensityEntryRemoteSource(result: .success([flour, honey]))
        let useCase = DefaultRefreshDensityCacheUseCase(remoteSource: remote, cacheRepository: cache)

        try await useCase.executeIfCacheEmpty()

        XCTAssertEqual(remote.fetchCount, 1)
        XCTAssertEqual(cache.entries, [flour, honey])
    }

    func testExecuteIfCacheEmptySkipsTheFetchWhenEntriesAreCached() async throws {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let remote = StubDensityEntryRemoteSource(result: .success([honey]))
        let useCase = DefaultRefreshDensityCacheUseCase(remoteSource: remote, cacheRepository: cache)

        try await useCase.executeIfCacheEmpty()

        XCTAssertEqual(remote.fetchCount, 0)
        XCTAssertEqual(cache.entries, [flour])
    }

    /// PLAN.md 10.1 acceptance: after one fetch, density lookups work with the network off.
    func testLookupsWorkOfflineAfterOneFetch() async throws {
        let container = try DensityStore.makeContainer(inMemory: true)
        let cache = SwiftDataDensityCacheRepository(modelContext: container.mainContext)
        let remote = StubDensityEntryRemoteSource(result: .success([flour, honey]))
        try await DefaultRefreshDensityCacheUseCase(remoteSource: remote, cacheRepository: cache).executeIfCacheEmpty()

        remote.result = .failure(URLError(.notConnectedToInternet))
        let refreshUseCase = DefaultRefreshDensityCacheUseCase(remoteSource: remote, cacheRepository: cache)
        try await refreshUseCase.executeIfCacheEmpty()
        let lookUp = DefaultLookUpDensityUseCase(cacheRepository: cache)

        XCTAssertEqual(try lookUp.execute(ingredientName: "Honey")?.gramsPerMilliliter, 1.42)
        XCTAssertEqual(remote.fetchCount, 1)
    }
}
