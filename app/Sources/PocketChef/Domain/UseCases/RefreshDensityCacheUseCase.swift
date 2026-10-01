import Foundation

@MainActor
protocol RefreshDensityCacheUseCase {
    /// When the cache was last refreshed successfully on this device, or nil if never.
    var lastRefresh: Date? { get }
    /// Downloads every entry and updates the cache to match (Settings' "Refresh Now").
    @discardableResult
    func execute() async throws -> DensityCacheChanges
    /// The periodic check: refreshes only when the cache is empty or the last refresh is older
    /// than a day. Returns nil when it didn't need to.
    @discardableResult
    func executeIfStale() async throws -> DensityCacheChanges?
}

@MainActor
final class DefaultRefreshDensityCacheUseCase: RefreshDensityCacheUseCase {
    static let maximumAge: TimeInterval = 24 * 60 * 60

    private let remoteSource: DensityEntryRemoteSource
    private let cacheRepository: DensityCacheRepository
    private let refreshLog: DensityRefreshLog
    private let now: () -> Date
    /// The refresh in progress. Activation and a tap on Refresh Now can overlap; the second
    /// request waits for this one instead of downloading again.
    private var inFlight: Task<DensityCacheChanges, Error>?

    init(
        remoteSource: DensityEntryRemoteSource,
        cacheRepository: DensityCacheRepository,
        refreshLog: DensityRefreshLog,
        now: @escaping () -> Date = Date.init
    ) {
        self.remoteSource = remoteSource
        self.cacheRepository = cacheRepository
        self.refreshLog = refreshLog
        self.now = now
    }

    var lastRefresh: Date? {
        refreshLog.lastRefresh
    }

    @discardableResult
    func execute() async throws -> DensityCacheChanges {
        if let inFlight {
            return try await inFlight.value
        }
        // Main-actor isolated, like the cache and log it writes: only the download leaves it.
        let task = Task { @MainActor [remoteSource, cacheRepository, refreshLog, now] in
            let entries = try await remoteSource.fetchAll()
            let changes = try cacheRepository.apply(entries)
            refreshLog.recordRefresh(at: now())
            return changes
        }
        inFlight = task
        defer { inFlight = nil }
        return try await task.value
    }

    @discardableResult
    func executeIfStale() async throws -> DensityCacheChanges? {
        guard try isStale() else { return nil }
        return try await execute()
    }

    private func isStale() throws -> Bool {
        if try cacheRepository.isEmpty() { return true }
        guard let lastRefresh = refreshLog.lastRefresh else { return true }
        return now().timeIntervalSince(lastRefresh) >= Self.maximumAge
    }
}
