#if DEBUG
import Foundation

/// Feeds `SampleData` into SwiftUI previews without touching a real SwiftData store.
struct PreviewRecipeRepository: RecipeRepository {
    func fetchAll() throws -> [Recipe] {
        SampleData.recipes
    }
}
#endif
