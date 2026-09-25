import Foundation

struct Recipe: Identifiable, Equatable {
    let id: UUID
    var title: String
    var ingredients: [IngredientLine]
    /// Tools and cookware the recipe needs ("loaf pan", "whisk"), kept out of `ingredients`.
    var equipment: [String] = []
    var steps: [String]
    var source: RecipeSource
    var tags: [Tag]
}

enum RecipeSource: Equatable {
    case typed
    case url(URL)
}
