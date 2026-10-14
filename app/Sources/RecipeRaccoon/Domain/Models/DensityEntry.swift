import Foundation

/// How many grams one milliliter of an ingredient weighs, from the density API.
struct DensityEntry: Identifiable, Equatable {
    var ingredientName: String
    var gramsPerMilliliter: Double
    /// When the entry last changed on the server. Phase 10.2 diffs against it.
    var lastModified: Date

    var id: String {
        Self.lookupKey(for: ingredientName)
    }

    /// The form two ingredient names are compared in. The API canonicalizes names to NFC and
    /// trims them (`IngredientNames.Canonicalize`), and its citext index ignores case, so names
    /// differing only in those ways are the same entry (issue #55).
    static func lookupKey(for ingredientName: String) -> String {
        ingredientName.precomposedStringWithCanonicalMapping
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
