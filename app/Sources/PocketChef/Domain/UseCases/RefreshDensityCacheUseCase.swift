import Foundation

@MainActor
protocol RefreshDensityCacheUseCase {
    /// Downloads every entry and replaces the cache with them.
    func execute() async throws
    /// The launch path: downloads only when nothing is cached yet.
    func executeIfCacheEmpty() async throws
}

@MainActor
final class DefaultRefreshDensityCacheUseCase: RefreshDensityCacheUseCase {
    private let remoteSource: DensityEntryRemoteSource
    private let cacheRepository: DensityCacheRepository

    init(remoteSource: DensityEntryRemoteSource, cacheRepository: DensityCacheRepository) {
        self.remoteSource = remoteSource
        self.cacheRepository = cacheRepository
    }

    func execute() async throws {
        let entries = try await remoteSource.fetchAll()
        try cacheRepository.replaceAll(with: entries)
    }

    func executeIfCacheEmpty() async throws {
        guard try cacheRepository.isEmpty() else { return }
        try await execute()
    }
}
