import Foundation
import SwiftData

extension RecipeModel {
    func toDomain() -> Recipe {
        Recipe(
            id: id,
            title: title,
            ingredients: (ingredients ?? []).sorted { $0.position < $1.position }.map { $0.toDomain() },
            equipment: equipment,
            steps: steps,
            // isTypedSource/sourceURL are only ever set together via toModel(), so this pairing always holds.
            source: isTypedSource ? .typed : .url(sourceURL!),
            tags: (tags ?? []).map { $0.toDomain() }
        )
    }
}

extension Recipe {
    func toModel() -> RecipeModel {
        let isTyped: Bool
        let url: URL?
        switch source {
        case .typed:
            isTyped = true
            url = nil
        case let .url(sourceURL):
            isTyped = false
            url = sourceURL
        }

        // tags is deliberately omitted (defaults to []): tags are a shared relationship
        // resolved to already-persisted TagModel rows by SwiftDataRecipeRepository, never
        // built via toModel() — see resolveTagModels(for:).
        return RecipeModel(
            id: id,
            title: title,
            steps: steps,
            equipment: equipment,
            isTypedSource: isTyped,
            sourceURL: url,
            ingredients: ingredientModels()
        )
    }

    /// Ingredient rows numbered by their index, since SwiftData doesn't keep the
    /// order of to-many relationships (RecipeModel.toDomain() sorts by position).
    func ingredientModels() -> [IngredientLineModel] {
        ingredients.enumerated().map { index, line in line.toModel(position: index) }
    }
}

extension RecipeModel {
    /// Replaces every field except tags with `recipe`'s. Tags are left to the caller,
    /// because they're a shared relationship that must resolve to rows already in `context`.
    func overwrite(with recipe: Recipe, in context: ModelContext) {
        title = recipe.title
        steps = recipe.steps
        equipment = recipe.equipment
        switch recipe.source {
        case .typed:
            isTypedSource = true
            sourceURL = nil
        case let .url(url):
            isTypedSource = false
            sourceURL = url
        }

        // The .cascade delete rule only fires on parent deletion, not on reassigning
        // the relationship array, so old children must be deleted explicitly here or
        // they leak as orphaned rows.
        (ingredients ?? []).forEach { context.delete($0) }
        ingredients = recipe.ingredientModels()
    }
}
