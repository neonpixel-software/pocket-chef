import Foundation
import SwiftData

/// Copies recipes and tags between two stores when the storage mode changes.
enum RecipeStoreCopier {
    /// Upserts every recipe in `source` into `target` by id, and copies every tag
    /// (used or not). A recipe already in `target` is overwritten with the source version.
    /// Tags are matched by name, ignoring case, so presets aren't duplicated.
    static func merge(from source: ModelContext, into target: ModelContext) throws {
        var tagsByKey = try Dictionary(
            target.fetch(FetchDescriptor<TagModel>()).map { (key(for: $0.name), $0) },
            uniquingKeysWith: { first, _ in first }
        )
        func resolve(_ tag: TagModel) -> TagModel {
            if let existing = tagsByKey[key(for: tag.name)] { return existing }
            let copy = TagModel(id: tag.id, name: tag.name, isPreset: tag.isPreset)
            target.insert(copy)
            tagsByKey[key(for: tag.name)] = copy
            return copy
        }

        for tag in try source.fetch(FetchDescriptor<TagModel>()) {
            _ = resolve(tag)
        }

        let targetRecipes = try Dictionary(
            target.fetch(FetchDescriptor<RecipeModel>()).map { ($0.id, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        for sourceRecipe in try source.fetch(FetchDescriptor<RecipeModel>()) {
            let recipe = sourceRecipe.toDomain()
            let model: RecipeModel
            if let existing = targetRecipes[recipe.id] {
                existing.overwrite(with: recipe, in: target)
                model = existing
            } else {
                model = recipe.toModel()
                target.insert(model)
            }
            model.tags = (sourceRecipe.tags ?? []).map(resolve)
        }

        try target.save()
    }

    /// Empties `target`, then fills it with everything in `source`.
    static func replace(contentsOf target: ModelContext, with source: ModelContext) throws {
        // Row by row rather than delete(model:), which may skip the .cascade rule and
        // leave ingredient lines orphaned.
        try target.fetch(FetchDescriptor<RecipeModel>()).forEach { target.delete($0) }
        try target.fetch(FetchDescriptor<TagModel>()).forEach { target.delete($0) }
        try target.save()
        try merge(from: source, into: target)
    }

    private static func key(for name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
