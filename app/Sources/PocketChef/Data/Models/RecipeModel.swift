import Foundation
import SwiftData

@Model
final class RecipeModel {
    var id: UUID = UUID()
    var title: String = ""
    var steps: [String] = []
    var isTypedSource: Bool = false
    var sourceURL: URL?
    @Relationship(deleteRule: .cascade) var ingredients: [IngredientLineModel]? = []
    @Relationship var tags: [TagModel]? = []

    init(
        id: UUID = UUID(),
        title: String,
        steps: [String],
        isTypedSource: Bool,
        sourceURL: URL? = nil,
        ingredients: [IngredientLineModel] = [],
        tags: [TagModel] = []
    ) {
        self.id = id
        self.title = title
        self.steps = steps
        self.isTypedSource = isTypedSource
        self.sourceURL = sourceURL
        self.ingredients = ingredients
        self.tags = tags
    }
}
