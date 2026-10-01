import Foundation

/// The on-device copy of the density entries, so lookups work offline.
protocol DensityCacheRepository {
    /// Replaces every cached entry, so entries removed on the server disappear too.
    func replaceAll(with entries: [DensityEntry]) throws
    /// Matches names the way the API does (see `DensityEntry.lookupKey(for:)`).
    func entry(forIngredientNamed name: String) throws -> DensityEntry?
    func isEmpty() throws -> Bool
}
