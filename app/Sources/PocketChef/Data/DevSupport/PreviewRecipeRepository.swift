#if DEBUG
import Foundation

/// Feeds `SampleData` into SwiftUI previews without touching a real SwiftData store.
struct PreviewRecipeRepository: RecipeRepository {
    func fetchAll() throws -> [Recipe] {
        SampleData.recipes
    }

    func create(_: Recipe) throws { /* no-op: previews render fixed SampleData, never persisted */ }
    func update(_: Recipe) throws { /* no-op: previews render fixed SampleData, never persisted */ }
    func delete(id _: UUID) throws { /* no-op: previews render fixed SampleData, never persisted */ }
}
#endif
