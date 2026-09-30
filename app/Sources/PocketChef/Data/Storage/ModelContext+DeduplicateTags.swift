import Foundation
import SwiftData

extension ModelContext {
    /// Merges tags whose names match ignoring case and surrounding whitespace.
    ///
    /// CloudKit has no unique constraints, and every device seeds the preset tags into its own
    /// iCloud store before its first import, so after a sync the same "Breakfast" arrives twice.
    /// The kept row is chosen deterministically (a preset before a custom tag, then the smallest
    /// id) so two devices deduplicating at the same time keep the same row, rather than each
    /// deleting the other's copy and losing both.
    ///
    /// Saves only when it found duplicates, so running it on every remote change can't loop.
    /// Returns whether anything changed.
    @discardableResult
    func deduplicateTags() throws -> Bool {
        let tags = try fetch(FetchDescriptor<TagModel>())
        let groups = Dictionary(grouping: tags) { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }

        var changed = false
        for group in groups.values where group.count > 1 {
            let sorted = group.sorted { lhs, rhs in
                if lhs.isPreset != rhs.isPreset { return lhs.isPreset }
                return lhs.id.uuidString < rhs.id.uuidString
            }
            let keeper = sorted[0]
            for duplicate in sorted.dropFirst() {
                for recipe in duplicate.recipes ?? [] {
                    var recipeTags = (recipe.tags ?? []).filter { $0 !== duplicate }
                    if !recipeTags.contains(where: { $0 === keeper }) {
                        recipeTags.append(keeper)
                    }
                    recipe.tags = recipeTags
                }
                delete(duplicate)
            }
            changed = true
        }

        if changed {
            try save()
        }
        return changed
    }
}
