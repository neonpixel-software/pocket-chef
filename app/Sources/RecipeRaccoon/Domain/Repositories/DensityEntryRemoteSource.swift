import Foundation

/// Reads every entry from the density API.
protocol DensityEntryRemoteSource: Sendable {
    func fetchAll() async throws -> [DensityEntry]
}

enum DensityEntryFetchError: Error {
    case requestFailed(underlying: Error)
    case httpStatus(Int)
    case invalidResponse(underlying: Error)
}
