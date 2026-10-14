import Foundation
import SwiftData

/// A cached density entry. It lives in the local-only density store (DensityStore), never in
/// a recipe store, so the unique key is allowed (CloudKit forbids unique constraints).
@Model
final class DensityEntryModel {
    /// `DensityEntry.lookupKey(for: ingredientName)`, so a lookup is one indexed fetch.
    @Attribute(.unique) var lookupKey: String = ""
    var ingredientName: String = ""
    var gramsPerMilliliter: Double = 0
    var lastModified: Date = Date.distantPast

    init(ingredientName: String, gramsPerMilliliter: Double, lastModified: Date) {
        lookupKey = DensityEntry.lookupKey(for: ingredientName)
        self.ingredientName = ingredientName
        self.gramsPerMilliliter = gramsPerMilliliter
        self.lastModified = lastModified
    }
}
