import Foundation

/// What a refresh changed in the cache.
struct DensityCacheChanges: Equatable {
    var added = 0
    var updated = 0
    var removed = 0

    var isEmpty: Bool {
        added == 0 && updated == 0 && removed == 0
    }
}

/// The on-device copy of the density entries, so lookups work offline.
protocol DensityCacheRepository {
    /// Makes the cache match `entries`, the server's full table: inserts new entries, updates
    /// changed ones and deletes the ones the server no longer has.
    func apply(_ entries: [DensityEntry]) throws -> DensityCacheChanges
    /// Matches names the way the API does (see `DensityEntry.lookupKey(for:)`).
    func entry(forIngredientNamed name: String) throws -> DensityEntry?
    func isEmpty() throws -> Bool
}
