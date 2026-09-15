#if DEBUG
import Foundation

/// Feeds `SampleData` into SwiftUI previews without touching a real SwiftData store.
struct PreviewRecipeRepository: RecipeRepository {
    func fetchAll() throws -> [Recipe] {
        SampleData.recipes
    }

    func create(_ recipe: Recipe) throws {}
    func update(_ recipe: Recipe) throws {}
    func delete(id: UUID) throws {}
}
#endif
