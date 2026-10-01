@testable import PocketChef
import XCTest

private final class StubDensityEntryRemoteSource: DensityEntryRemoteSource, @unchecked Sendable {
    var result: Result<[DensityEntry], Error>
    private(set) var fetchCount = 0
    /// When set, fetches wait for a value on it, so a test can overlap two refreshes. The
    /// stream buffers, so a release sent before the fetch starts waiting isn't lost.
    var holdUntil: AsyncStream<Void>?

    init(result: Result<[DensityEntry], Error>) {
        self.result = result
    }

    func fetchAll() async throws -> [DensityEntry] {
        fetchCount += 1
        if let holdUntil {
            for await _ in holdUntil {
                break
            }
        }
        return try result.get()
    }
}

private final class FakeDensityCacheRepository: DensityCacheRepository {
    var entries: [DensityEntry] = []

    func apply(_ entries: [DensityEntry]) throws -> DensityCacheChanges {
        // The real repository writes the main context, so it must never run off the main actor.
        MainActor.assertIsolated()
        let changes = DensityCacheChanges(added: entries.count(where: { !self.entries.contains($0) }))
        self.entries = entries
        return changes
    }

    func entry(forIngredientNamed name: String) throws -> DensityEntry? {
        entries.first { $0.id == DensityEntry.lookupKey(for: name) }
    }

    func isEmpty() throws -> Bool {
        entries.isEmpty
    }
}

private final class FakeDensityRefreshLog: DensityRefreshLog {
    var lastRefresh: Date?

    func recordRefresh(at date: Date) {
        MainActor.assertIsolated()
        lastRefresh = date
    }
}

@MainActor
final class RefreshDensityCacheUseCaseTests: XCTestCase {
    private let flour = DensityEntry(ingredientName: "flour", gramsPerMilliliter: 0.53, lastModified: Date(timeIntervalSince1970: 1))
    private let honey = DensityEntry(ingredientName: "honey", gramsPerMilliliter: 1.42, lastModified: Date(timeIntervalSince1970: 2))
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    private func makeUseCase(
        remote: StubDensityEntryRemoteSource,
        cache: DensityCacheRepository = FakeDensityCacheRepository(),
        log: FakeDensityRefreshLog = FakeDensityRefreshLog()
    ) -> DefaultRefreshDensityCacheUseCase {
        DefaultRefreshDensityCacheUseCase(remoteSource: remote, cacheRepository: cache, refreshLog: log, now: { [now] in now })
    }

    func testExecuteUpdatesTheCacheAndRecordsTheRefresh() async throws {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let log = FakeDensityRefreshLog()
        let useCase = makeUseCase(remote: StubDensityEntryRemoteSource(result: .success([flour, honey])), cache: cache, log: log)

        let changes = try await useCase.execute()

        XCTAssertEqual(changes, DensityCacheChanges(added: 1))
        XCTAssertEqual(cache.entries, [flour, honey])
        XCTAssertEqual(log.lastRefresh, now)
        XCTAssertEqual(useCase.lastRefresh, now)
    }

    func testAFailedRefreshLeavesTheCacheAndTheLogAlone() async {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let log = FakeDensityRefreshLog()
        log.lastRefresh = Date(timeIntervalSince1970: 5)
        let useCase = makeUseCase(
            remote: StubDensityEntryRemoteSource(result: .failure(URLError(.notConnectedToInternet))),
            cache: cache,
            log: log
        )

        do {
            try await useCase.execute()
            XCTFail("Expected the fetch error")
        } catch {
            XCTAssertEqual((error as? URLError)?.code, .notConnectedToInternet)
        }
        XCTAssertEqual(cache.entries, [flour])
        XCTAssertEqual(log.lastRefresh, Date(timeIntervalSince1970: 5))
    }

    func testExecuteIfStaleRefreshesAnEmptyCache() async throws {
        let log = FakeDensityRefreshLog()
        log.lastRefresh = now
        let remote = StubDensityEntryRemoteSource(result: .success([flour]))

        let changes = try await makeUseCase(remote: remote, log: log).executeIfStale()

        XCTAssertEqual(changes, DensityCacheChanges(added: 1))
        XCTAssertEqual(remote.fetchCount, 1)
    }

    /// Caches filled by 10.1 have entries but no recorded refresh.
    func testExecuteIfStaleRefreshesWhenNoRefreshWasRecorded() async throws {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let remote = StubDensityEntryRemoteSource(result: .success([flour]))

        try await makeUseCase(remote: remote, cache: cache).executeIfStale()

        XCTAssertEqual(remote.fetchCount, 1)
    }

    func testExecuteIfStaleSkipsARefreshLessThanADayOld() async throws {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let log = FakeDensityRefreshLog()
        log.lastRefresh = now.addingTimeInterval(-DefaultRefreshDensityCacheUseCase.maximumAge + 60)
        let remote = StubDensityEntryRemoteSource(result: .success([honey]))

        let changes = try await makeUseCase(remote: remote, cache: cache, log: log).executeIfStale()

        XCTAssertNil(changes)
        XCTAssertEqual(remote.fetchCount, 0)
        XCTAssertEqual(cache.entries, [flour])
    }

    func testExecuteIfStaleRefreshesADayOldCache() async throws {
        let cache = FakeDensityCacheRepository()
        cache.entries = [flour]
        let log = FakeDensityRefreshLog()
        log.lastRefresh = now.addingTimeInterval(-DefaultRefreshDensityCacheUseCase.maximumAge)
        let remote = StubDensityEntryRemoteSource(result: .success([flour, honey]))

        try await makeUseCase(remote: remote, cache: cache, log: log).executeIfStale()

        XCTAssertEqual(remote.fetchCount, 1)
        XCTAssertEqual(log.lastRefresh, now)
    }

    func testOverlappingRefreshesShareOneDownload() async throws {
        let remote = StubDensityEntryRemoteSource(result: .success([flour]))
        let (release, releaseContinuation) = AsyncStream<Void>.makeStream()
        remote.holdUntil = release
        let useCase = makeUseCase(remote: remote)

        let first = Task { try await useCase.execute() }
        while remote.fetchCount == 0 {
            await Task.yield()
        }
        let second = Task { try await useCase.execute() }
        // Let the second refresh reach the in-flight one before the download finishes.
        for _ in 0..<20 {
            await Task.yield()
        }
        releaseContinuation.yield()
        releaseContinuation.finish()
        let results = try await [first.value, second.value]

        XCTAssertEqual(remote.fetchCount, 1)
        XCTAssertEqual(results, [DensityCacheChanges(added: 1), DensityCacheChanges(added: 1)])
    }

    /// PLAN.md 10.1 acceptance: after one fetch, density lookups work with the network off.
    func testLookupsWorkOfflineAfterOneFetch() async throws {
        let container = try DensityStore.makeContainer(inMemory: true)
        let cache = SwiftDataDensityCacheRepository(modelContext: container.mainContext)
        let remote = StubDensityEntryRemoteSource(result: .success([flour, honey]))
        let useCase = makeUseCase(remote: remote, cache: cache)
        try await useCase.executeIfStale()

        remote.result = .failure(URLError(.notConnectedToInternet))
        try await useCase.executeIfStale()
        let lookUp = DefaultLookUpDensityUseCase(cacheRepository: cache)

        XCTAssertEqual(try lookUp.execute(ingredientName: "Honey")?.gramsPerMilliliter, 1.42)
        XCTAssertEqual(remote.fetchCount, 1)
    }

    /// PLAN.md 10.2 acceptance: an entry added on the server reaches the cache on a manual refresh.
    func testRefreshNowBringsInAnEntryAddedOnTheServer() async throws {
        let container = try DensityStore.makeContainer(inMemory: true)
        let cache = SwiftDataDensityCacheRepository(modelContext: container.mainContext)
        let remote = StubDensityEntryRemoteSource(result: .success([flour]))
        let useCase = makeUseCase(remote: remote, cache: cache)
        try await useCase.executeIfStale()
        let mapleSyrup = DensityEntry(ingredientName: "maple syrup", gramsPerMilliliter: 1.33, lastModified: Date(timeIntervalSince1970: 3))

        remote.result = .success([flour, mapleSyrup])
        let periodicChanges = try await useCase.executeIfStale()
        XCTAssertNil(periodicChanges, "fresh cache: no periodic refresh")
        let changes = try await useCase.execute()

        XCTAssertEqual(changes, DensityCacheChanges(added: 1))
        XCTAssertEqual(try DefaultLookUpDensityUseCase(cacheRepository: cache).execute(ingredientName: "Maple Syrup"), mapleSyrup)
    }
}
