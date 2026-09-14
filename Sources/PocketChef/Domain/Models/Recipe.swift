import Foundation

struct Recipe: Identifiable, Equatable {
    let id: UUID
    var title: String
    var ingredients: [IngredientLine]
    var steps: [String]
    var source: RecipeSource
    var tags: [Tag]
}

enum RecipeSource: Equatable {
    case typed
    case url(URL)
}
