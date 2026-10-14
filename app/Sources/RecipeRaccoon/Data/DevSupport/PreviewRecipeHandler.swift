#if DEBUG
/// The callback SwiftUI previews pass where a view hands back a captured or saved recipe.
enum PreviewRecipeHandler {
    static func ignore(_: Recipe) {
        // Nothing to do: a preview has nowhere to save a recipe.
    }
}
#endif
