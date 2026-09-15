import Foundation
import SwiftData

extension ModelContext {
    /// Seeds the built-in preset tags on first launch. Unlike sample-recipe seeding,
    /// this runs in every build (including release) since presets must always exist.
    ///
    /// Seeds each preset individually rather than bailing out if any preset-flagged tag
    /// already exists — a store seeded before a preset list change (or one seeded with
    /// ad-hoc "preset-like" tags from sample data) could otherwise end up permanently
    /// missing the newly-added presets.
    func seedPresetTagsIfNeeded() {
        let existingNames = Set(((try? fetch(FetchDescriptor<TagModel>())) ?? []).map { $0.name.lowercased() })
        let missingPresets = ["Breakfast", "Lunch", "Dinner", "Dessert", "Snack"]
            .filter { !existingNames.contains($0.lowercased()) }
        guard !missingPresets.isEmpty else { return }

        for name in missingPresets {
            insert(TagModel(name: name, isPreset: true))
        }
        try? save()
    }
}
