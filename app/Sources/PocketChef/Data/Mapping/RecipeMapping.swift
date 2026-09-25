import Foundation

extension RecipeModel {
    func toDomain() -> Recipe {
        Recipe(
            id: id,
            title: title,
            ingredients: (ingredients ?? []).map { $0.toDomain() },
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
            ingredients: ingredients.map { $0.toModel() }
        )
    }
}
